#!/usr/bin/perl

use strict;
use warnings;
use File::Temp qw/tempfile/;
use GD;
use WebService::TenkiJp::Radar::Image;

my $gifdata;
my @forecast = qw/60 120 180 240 300 360/;
for my $index (0..$#forecast){
    my $image = WebService::TenkiJp::Radar::Image->new()->get_image(area => 3, forecast => $forecast[$index]);

    #一旦ファイルに保存してから GD で画像を読み込む
    my ($fh, $path ) = tempfile();
    binmode $fh;
    print $fh $image;
    close $fh;
    my $frame = GD::Image->new($path);
    unlink $path; #読み込んだら元ファイルは不要

    if($index == 0){
        $gifdata = $frame->gifanimbegin(1,0);
    }

    #gif animation としてデータ連結
    $gifdata .= $frame->gifanimadd(1,0,0,100);

    if($index == $#forecast){
        $gifdata .= $frame->gifanimend;
    }

}

open my $fh, '>', './image_ja_forecast_animation.gif';
binmode $fh;
print $fh $gifdata;
close $fh;
