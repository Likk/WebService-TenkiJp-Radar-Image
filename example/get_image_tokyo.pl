#!/usr/bin/perl

use strict;
use warnings;
use WebService::TenkiJp::Radar::Image;

my $image = WebService::TenkiJp::Radar::Image->new()->get_image('pref', 16);
open my $fh, '>', './image.jpg';
binmode $fh;
print $fh $image;
close $fh;
