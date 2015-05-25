#!/usr/bin/perl

use strict;
use warnings;
use WebService::TenkiJp::Radar::Image;

my $image = WebService::TenkiJp::Radar::Image->new()->get_image(forecast => 180);
open my $fh, '>', './image_ja_forecast.jpg';
binmode $fh;
print $fh $image;
close $fh;
