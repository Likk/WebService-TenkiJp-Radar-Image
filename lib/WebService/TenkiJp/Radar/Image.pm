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
use WWW::Mechanize;
use Web::Scraper;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw/pref pref_list/);

our $VERSION = '0.01';
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
our $BASE_URL        = q{http://tenki.jp};


sub get_image {
  my $self = shift;
  my %args = @_;
  my $pref = defined $args{pref} ? $args{pref} : $self->pref;
  Carp::confess('requested pref code') unless $pref;

  $self->_make_ua();
  my $res     = $self->{ua}->get("@{[$BASE_URL]}/forecast/pref-@{[$pref]}.html");
  my $content = $res->decoded_content();
  my $image_url;

  # http://az416740.vo.msecnd.net/static-images/rader/recent_entry/pref_16/small.jpg
  if($content =~ m{img\ssrc="(http://.*?/static-images/rader/recent_entry/pref_[0-9]+/small.jpg)}){
    $image_url = $1;
  }
  Carp::confess('cant find image url') unless $image_url;

  $res     = $self->{ua}->get($image_url);
  $content = $res->decoded_content();
  return $content
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
