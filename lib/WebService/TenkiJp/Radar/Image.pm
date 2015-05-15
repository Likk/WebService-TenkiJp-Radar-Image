package WebService::TenkiJp::Radar::Image;

=encoding utf8

=head1 NAME

WebService::TenkiJp::Radar::Image - tenki.jp weather radar image.

=head1 SYNOPSIS

  use WebService::TenkiJp::Radar::Image;
  use YAML;

  warn YAML::Dump WebService::TenkiJp::Radar::Image->get_pref_list();

  my $radar = WebService::TenkiJp::Radar::Image->new(prefecture => 16, #Tokyo);
  my $image = $radar->get_image;

  OR

  my $image = WebService::TenkiJp::Radar::Image->new()->get_image(prefecture => 16);

  open( my $fh, '>', /path/to/image.jpg);
  binmode $fh;
  print $fh $image;
  close $fh;

=head1 DESCRIPTION

WebService::TenkiJp::Radar::Image will Downloader weather radar image of the tenki.jp.

=cut

use strict;
use warnings;
use utf8;
use base       qw/Class::Accessor::Fast/;
use Carp;
use HTTP::Date qw/parse_date/;
use WWW::Mechanize;

__PACKAGE__->mk_accessors(qw/prefecture area/);

our $VERSION  = '2.00';
our $BASE_URL = q{http://tenki.jp};

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

=back

=cut

sub get_image {
  my $self = shift;
  my %args = @_;
  my $date = $args{date};

  my $image_url;
  my $img_reg = qr{img\ssrc="(http://(.*?/static-images/rader)/\d{4}/\d{2}/\d{2}/\d{2}/\d{2}/\d{2}/(?:(pref|area)_[0-9]+|japan_detail)/large.jpg)};
  # http://az416740.vo.msecnd.net/static-images/rader/2015/05/14/20/20/00/pref_16/large.jpg      #県情報
  # http://az416740.vo.msecnd.net/static-images/rader/2015/05/15/14/50/00/area_1/large.jpg       #地方情報
  # http://az416740.vo.msecnd.net/static-images/rader/2015/05/15/14/55/00/japan_detail/large.jpg #日本全体

  $self->_make_ua();
  if(my $res = $self->{ua}->get($self->get_radar_path(%args))){
    my $content = $res->decoded_content();
    if($content =~ $img_reg){
        $image_url = $1;
        if($date){
            my @dt   = parse_date("$date +0900");
            my $min  = int($dt[4]/10) * 10; #分単位画像はないので43分なら40分にと切り捨てる
            $image_url = sprintf(
               "http://%s/%02d/%02d/%02d/%02d/%02d/00/%s_%s/large.jpg",
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
        $res     = $self->{ua}->get($image_url);
        $content = $res->decoded_content();
        return $content
    }
    Carp::confess('cant find image url') unless $image_url;
  }
}

=head2 get_pref_list

tenki.jp 県エリア名一覧を取得する

=cut

sub get_pref_list {
  my $self = shift;
  my $in_pref_list = [];
  my $prefecture_list = $self->_prefecture_list();
  for my $index (0..$#{$prefecture_list}){
    push $in_pref_list, { $prefecture_list->[$index] => $index + 1 };
  }
  return $in_pref_list;
}

=head1 PRIVATE METHODS

=over

=item B<_make_ua>

http access 用の User Agent を作る

=cut

sub _make_ua {
  my $self = shift;
  my $ua   = WWW::Mechanize->new(agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:8.0) Gecko/20100101 Firefox/8.0');
  $self->{ua} = $ua;
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

=item B<_prefecture_list>

tenki.jp 県エリア名一覧
北海道が4つの地域名になっていて、純粋な都道府県一覧と異なる

=cut

sub _prefecture_list {
  my $self = shift;
  return [qw/
    道北
    道央
    道東
    道南
    青森
    岩手
    宮城
    秋田
    山形
    福島
    茨城
    栃木
    群馬
    埼玉
    千葉
    東京
    神奈川
    新潟
    富山
    石川
    福井
    山梨
    長野
    岐阜
    静岡
    愛知
    三重
    滋賀
    京都
    大阪
    兵庫
    奈良
    和歌山
    鳥取
    島根
    岡山
    広島
    山口
    徳島
    香川
    愛媛
    高知
    福岡
    佐賀
    長崎
    熊本
    大分
    宮崎
    鹿児島
    沖縄
  /];
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
