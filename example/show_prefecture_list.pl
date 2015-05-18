#!/usr/bin/perl

use strict;
use warnings;
use WebService::TenkiJp::Radar::Image;
use YAML;

my $list = WebService::TenkiJp::Radar::Image->new()->show_prefecture_list();
warn YAML::Dump $list;
