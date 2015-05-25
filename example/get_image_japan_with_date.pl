#!/usr/bin/perl

use strict;
use warnings;
use WebService::TenkiJp::Radar::Image;

my $image = WebService::TenkiJp::Radar::Image->new()->get_image(date => '2015-01-01 12:00:00');
open my $fh, '>', './image_ja_with_date.jpg';
binmode $fh;
print $fh $image;
close $fh;
