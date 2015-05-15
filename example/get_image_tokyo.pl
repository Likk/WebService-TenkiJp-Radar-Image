#!/usr/bin/perl

use strict;
use warnings;
use WebService::TenkiJp::Radar::Image;

my $image = WebService::TenkiJp::Radar::Image->new()->get_image(prefecture => 16);
open my $fh, '>', './image_tokyo.jpg';
binmode $fh;
print $fh $image;
close $fh;
