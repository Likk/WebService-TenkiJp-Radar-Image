#!/usr/bin/perl

use strict;
use warnings;
use WebService::TenkiJp::Radar::Image;

my $image = WebService::TenkiJp::Radar::Image->new()->get_image('area' => 3);
open my $fh, '>', './image_kantou-koshin.jpg';
binmode $fh;
print $fh $image;
close $fh;
