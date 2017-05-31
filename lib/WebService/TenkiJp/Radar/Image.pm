package WebService::TenkiJp::Radar::Image;

=encoding utf8

=head1 NAME

  WebService::TenkiJp::Radar::Image - tenki.jp weather radar image.

=head1 SYNOPSIS

  use WebService::TenkiJp::Radar::Image;
  use YAML;

  warn YAML::Dump WebService::TenkiJp::Radar::Image->show_prefecture_list();

  my $radar = WebService::TenkiJp::Radar::Image->new()
  my $image = $radar->get_image(prefecture => 16);     #tokyo

  open( my $fh, '>', /path/to/image.jpg) or die;
  binmode $fh;
  print $fh $image;
  close $fh;

=head1 DESCRIPTION

  WebService::TenkiJp::Radar::Image will Downloader weather radar image of the tenki.jp.

=cut

use strict;
use warnings;
use utf8;
use parent       qw/Class::Accessor::Fast/;
use Carp;
use HTTP::Date qw/parse_date/;
use WWW::Mechanize;
use Web::Scraper;

__PACKAGE__->mk_accessors(qw/prefecture area/);

=head1 PACKAGE GLOBAL VARIABLE

=orver

=item B<VERSION> this version.

=item B<BASE_URL> tenki jp root address.

=item B<RADAR_IMAGE_REGEXP>

  radar image link tag regexp.
  #XXX: 2008/08 ~ 2017/05/31
  #XXX: http://az416740.vo.msecnd.net/static-images/rader/2015/05/14/20/20/00/pref_16/large.jpg      #県情報
  #XXX: http://az416740.vo.msecnd.net/static-images/rader/2015/05/15/14/50/00/area_1/large.jpg       #地方情報
  #XXX: http://az416740.vo.msecnd.net/static-images/rader/2015/05/15/14/55/00/japan_detail/large.jpg #日本全体
  #XXX: 2017/05/31 ~
  #XXX: https://static.tenki.jp/static-images/radar/2017/05/31/09/15/00/pref-16-large.jpg      #県情報
  #XXX: https://static.tenki.jp/static-images/radar/2017/05/30/12/00/00/area-3-large.jpg       #地方情報
  #XXX: https://static.tenki.jp/static-images/radar/2017/05/30/12/00/00/japan-detail-large.jpg #日本全体

=item B<FORECAST_IMAGE_REGEXP>

forecast radar image link tag regexp.

  XXX: https://static.tenki.jp/static-images/rainmesh/360/pref-16-large.jpg pref, forecast on after 360 minuites.

=back

=cut

our $VERSION               = '3.02';
our $BASE_URL              = q{https://tenki.jp};
our $RADAR_IMAGE_REGEXP    = qr{img\ssrc="(https://(static.tenki.jp/static-images/radar)/\d{4}/\d{2}/\d{2}/\d{2}/\d{2}/\d{2}/(?:(pref|area)-[0-9]+|japan-detail)-large.jpg)};

our $FORECAST_IMAGE_REGEXP = qr{img\ssrc="(https://(static.tenki.jp/static-images/rainmesh)/\d{2,3}/(?:pref|area-[0-9]+|japan-detail)-large.jpg)};

=head1 CONSTRUCTOR AND STARTUP

=head2 new

Creates and returns a new radar object.

  my $lingr = WebService::TenkiJp::Radar::Image->new();

=head1 ACCESSOR

=over

=item B<prefecture>

県エリアID

=item B<area>

エリアID

=back

=head1 METHODS

=head2 area_id_from_pref_id

県 ID からエリア ID を取得する

=cut

sub area_id_from_pref_id {
  my $self = shift;
  my $pref = shift;
  my $area = $self->_area_prefecture();
  for my $area_id (sort keys %$area){
      my $found = scalar( grep { $_ == $pref; } @{ $area->{$area_id} });
      return $area_id if $found;
  }
  die 'cant find area id';
}

=head2 get_radar_path

radar ランディング URL を取得する

=cut

sub get_radar_path {
  my $self = shift;
  my %args = @_;
  my $path;

  if($args{prefecture} or $self->prefecture){
    my $pref = $args{prefecture} || $self->prefecture;
    $path = sprintf("%s/radar/%s/%s/",
      $BASE_URL,
      $self->area_id_from_pref_id($pref),
      $pref
    );
  }
  elsif($args{area} or $self->area){
      my $area = $args{area} || $self->area;
      $path = sprintf("%s/radar/%s/",
          $BASE_URL,
          $area
      );
  }
  else {
      $path = sprintf("%s/radar/",$BASE_URL);
  }
  return $path;
}

=head2 get_image

雨雲レーダ画像を取得する。初期値では日本全域の画像を取得

    my $image = $radar->get_image()

=over

=item B<prefecture>

県エリアの範囲画像を取得する

    my $image = $radar->get_image(prefecture => 16);

=item B<area>

エリアの範囲画像を取得する

    my $image = $radar->get_image(area => 3);

=item B<date>

特定日付の画像を取得する。形式はHTTP::Date::parse_date が読み取れる形式
    my $image = $radar->get_image(date => '2015-01-01 12:00:00');

=item B<forecast>
予報画像を取得する。60分後から360分後まで60分刻みの引数が許される
    my $image = $radar->get_image(forecast => 360);

=back

=cut

sub get_image {
    my $self = shift;
    my %args = @_;
    my $date     = $args{date} || HTTP::Date::time2iso(time);
    my $forecast = $args{forecast};
    die 'forcast argument can have one of (60|120|180|240|300|360) values.'
      if ($forecast && $forecast !~ m{(60|120|180|240|300|360)});

    if(my $res = $self->_ua()->get($self->get_radar_path(%args))){
        my $image_url;
        my $content = $res->decoded_content();
        warn $date;
        if($forecast && $content =~ $FORECAST_IMAGE_REGEXP){
            $image_url = $1;
            my $base_path = $2;
            my $area      = $3 || 'japan';
            my $datetime  = HTTP::Date::time2iso(time);
            $datetime  =~ s{[-:\s]}{}g;
            $datetime  =  substr($datetime, 0, 10) .  '0000';
            $base_path =~ s{rader}{rainmesh};

            $image_url = sprintf(
                "http://%s/%d/%s-%s-large.jpg?%d",
                $base_path,
                $forecast,
                $area,
                $args{prefecture} || $self->prefecture || $args{area} || $self->{area} || 'detail',
                $datetime
            );
        }
        elsif($date && $content =~ $RADAR_IMAGE_REGEXP){
            my @dt   = parse_date("$date +0900");
            my $min  = int($dt[4]/10) * 10; #分単位画像はないので43分なら40分にと切り捨てる
            $image_url = sprintf(
               "http://%s/%02d/%02d/%02d/%02d/%02d/00/%s-%s-large.jpg",
                $2,
                $dt[0],
                $dt[1],
                $dt[2],
                $dt[3],
                $min,
                $3                                                                     || 'japan',
                $args{prefecture} || $self->prefecture || $args{area} || $self->{area} || 'detail',
            );
        }
        Carp::confess('cant find image url') unless $image_url;
        $res     = $self->_ua()->get($image_url);
        return $res->decoded_content();
    }
    Carp::confess('cant get radar path');
}

=head2 show_prefecture_list

tenki.jp 県エリア名一覧
北海道が4つの地域名になっていて、純粋な都道府県一覧と異なる

北海道は prefecture がなく area しかない。
都道府県には含まれない小笠原諸島が　prefecture をもっているなど、前提知識が必要なのでそれを出力する


=cut

sub show_prefecture_list {
  my $self = shift;

  my $res     = $self->_ua->get($BASE_URL);
  my $content = $res->decoded_content();

  my $scraper = scraper {
    process '//div[@id="wrap_weathersVarious"]', data => scraper {
      process '//a', 'links[]' => scraper {
        process '/*', 'href' => '@href',
                      'name' => 'TEXT';
      };
    };
    result qw/data/;
  };
  my $links = $scraper->scrape($content)->{links};
  my @prefecture_list = sort {
    $a->{area} <=> $b->{area} or ($a->{prefecture} || 0) <=> ($b->{prefecture}|| 0)
  }
  map {
    my @traversals = split m{/}, $_->{href};
    my $list = {
      name       => $_->{name},
      area       => $traversals[2],
    };
    $list->{prefecture} = $traversals[3] if $traversals[3];
    $list;
  }
  grep {
    defined $_->{name} and $_->{name} ne ''
  } @$links;
  return [@prefecture_list];
}

=head1 PRIVATE METHODS

=over

=item B<_ua>

http access 用の User Agent を返す

=cut

sub _ua {
  my $self = shift;
  $self->{ua}  //= WWW::Mechanize->new(agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:53.0) Gecko/20100101 Firefox/53.0');
  return $self->{ua};
}

=item B<_area_prefecture>

どのエリアにどの県が入るか

=cut

sub _area_prefecture {
  return {
    1  => [1..4],
    2  => [5..10],
    3  => [qw/11 12 13 14 15 16 17 22 23/], #関東と甲信
    4  => [18..21],
    5  => [24..27],
    6  => [28..33],
    7  => [34..38],
    8  => [39..42],
    9  => [43..49],
    10 => [50],
  };
}

=back

=cut

1;

=head1 AUTHOR

likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>

=head1 SEE ALSO

L<http://tenki.jp/rader/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
