use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use HTTP::Date;
use WebService::TenkiJp::Radar::Image;

my $tenki     = WebService::TenkiJp::Radar::Image->new();
my $yesterday = HTTP::Date::time2iso(time - (60 * 60 * 24));

{
    my $tenki;

    subtest 'prepare' => sub {
        $tenki = WebService::TenkiJp::Radar::Image->new();
        isa_ok($tenki, 'WebService::TenkiJp::Radar::Image');
    };

    subtest 'show_prefecture_list' => sub {
       my $pref_list =  $tenki->show_prefecture_list();
       isa_ok $pref_list, 'ARRAY',     'pref list is array ref';
       isa_ok $pref_list->[0] ,'HASH', 'a hash in a list in a array';
       my $pref_name_test = 0;
       for my $row (@$pref_list){
           isa_ok $row ,'HASH', 'a hash in a list in a array';
           if(defined $row->{prefecture} and $row->{prefecture} == 16) {
               $pref_name_test = 1 if $row->{name} eq '東京都';
           }
       }
       ok $pref_name_test, 'tokyo found';
    };

    subtest 'area_id_from_pref_id' => sub {
        is $tenki->area_id_from_pref_id(16), 3, 'tokyo is in kantou-koushin';
        is $tenki->area_id_from_pref_id(44), 9, 'saga is in kyusyu';
    };

    subtest 'get_radar_path' => sub {
        like $tenki->get_radar_path(prefecture => 16), qr{radar/\d+/16};
        like $tenki->get_radar_path(area       => 3),  qr{radar/3};
        like $tenki->get_radar_path(),                 qr{radar};1
    };

    subtest 'get_image at prefecture' => sub {
        my $image = $tenki->get_image( prefecture => 16 );
        ok $image, 'get image contents';
        like $image, qr/^\xFF\xD8/, 'image is jpg';
    };

    subtest 'get_image_at_prefecture_with_date' => sub  {
        my $image = $tenki->get_image( prefecture => 16, date => $yesterday );
        ok $image, 'get image contents';
        like $image, qr/^\xFF\xD8/, 'image is jpg';
    };

    subtest 'get_image_at_prefecture_forecast' => sub  {
        my $image = $tenki->get_image( forecast => 360);
        ok $image, 'get image contents';
        like $image, qr/^\xFF\xD8/, 'image is jpg';
        throws_ok { $tenki->get_image( forecast => 1) } qr/forcast argument can have one of/, 'argument check.';
    };

    subtest 'get_image in area' => sub {
        my $image = $tenki->get_image( area => 3 );
        ok $image, 'get image contents';
        like $image, qr/^\xFF\xD8/, 'image is jpg';
    };

    subtest 'get_image on japan' => sub {
        my $image = $tenki->get_image();
        ok $image, 'get image contents';
        like $image, qr/^\xFF\xD8/, 'image is jpg';
    };
}

done_testing();
