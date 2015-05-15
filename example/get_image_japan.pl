#!/usr/bin/perl

use strict;
use warnings;
use WebService::TenkiJp::Radar::Image;

my $image = WebService::TenkiJp::Radar::Image->new()->get_image();
open my $fh, '>', './image_ja.jpg';
binmode $fh;
print $fh $image;
close $fh;
