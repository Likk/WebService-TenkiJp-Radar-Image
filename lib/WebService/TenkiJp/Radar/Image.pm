package WebService::TenkiJp::Radar::Image;

=head1 NAME

WebService::TenkiJp::Radar::Image - tenki.jp radar image getter.

=head1 SYNOPSIS

  use WebService::TenkiJp::Radar::Image;
  use YAML;

  warn YAML::Dump WebService::TenkiJp::Radar::Image->get_pref_list();

  my $radar = WebService::TenkiJp::Radar::Image->new(
    pref => 16, #Tokyo
  );
  my $image = $radar->get_image;

  OR

  my $image = WebService::TenkiJp::Radar::Image->new()->get_image(pref => 16);

  open( my $fh, '>', /path/to/image.jpg);
  binmode $fh;
  print $fh $image;
  close $fh;

=head1 DESCRIPTION

WebService::TenkiJp::Radar::Image is image getter at tenki.jp radar.

=cut

use strict;
use warnings;
use utf8;
use Carp;
use HTTP::Date qw/parse_date/;
use WWW::Mechanize;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw/pref/);

our $VERSION = '1.00';
our $PREFECTURE_LIST = [qw/
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

# どのエリアにどの県が入るか
our $AREA = {
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
our $BASE_URL        = q{http://tenki.jp};

sub area_id_from_pref_id {
    my $self = shift;
    my $pref = shift;
    for my $area_id (sort keys %$AREA){
        my $found = scalar( grep { $_ == $pref; } @{ $AREA->{$area_id} });
        return $area_id if $found;
    }
    die 'cant find area id';
}

sub get_image {
  my $self = shift;
  my %args = @_;
  my $pref = defined $args{pref} ? $args{pref} : $self->pref;
  my $date = $args{date};

  Carp::confess('requested pref code') unless $pref;

  my $image_url;
  my $img_reg =
qr{img\ssrc="(http://(.*?/static-images/rader)/\d{4}/\d{2}/\d{2}/\d{2}/\d{2}/\d{2}/pref_[0-9]+/large.jpg)};
  # http://az416740.vo.msecnd.net/static-images/rader/2015/05/14/20/20/00/pref_16/large.jpg

  $self->_make_ua();
  my $res     = $self->{ua}->get(sprintf("%s/radar/%s/%s/",
      $BASE_URL,
      $self->area_id_from_pref_id($pref),
      $pref)
  );
  if($res){
    my $content = $res->decoded_content();
    if($content =~ $img_reg){
        $image_url = $1;
        if($date){
            my @dt   = parse_date("$date +0900");
            $image_url = sprintf(
                "http://%s/%02d/%02d/%02d/%02d/%02d/00/pref_%s/large.jpg",
                $2,
                $dt[0],
                $dt[1],
                $dt[2],
                $dt[3],
                $dt[4],
                $pref,
            );
        }
        $res     = $self->{ua}->get($image_url);
        $content = $res->decoded_content();
        return $content
    }
    Carp::confess('cant find image url') unless $image_url;
  }
}

sub get_pref_list {
  my @_in_pref_list = ();
  for my $index (0..$#{$PREFECTURE_LIST}){
    push @_in_pref_list, { $PREFECTURE_LIST->[$index] => $index + 1 };
  }
  return \@_in_pref_list;
}

sub _make_ua {
  my $self = shift;
  my $ua   = WWW::Mechanize->new(agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:8.0) Gecko/20100101 Firefox/8.0');
  $self->{ua} = $ua;
}

1;

=head1 AUTHOR

likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
