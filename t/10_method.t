use strict;
use warnings;
use utf8;
use Test::More;
use WebService::TenkiJp::Radar::Image;

my $tenki = WebService::TenkiJp::Radar::Image->new();

{
    my $tenki;

    subtest 'prepare' => sub {
        $tenki = WebService::TenkiJp::Radar::Image->new();
        isa_ok($tenki, 'WebService::TenkiJp::Radar::Image');
    };

    subtest 'get_pref_list' => sub {
       my $pref_list =  $tenki->get_pref_list();
       isa_ok $pref_list, 'ARRAY',     'pref list is array ref';
       isa_ok $pref_list->[0] ,'HASH', 'a hash in a list in a array';
       my $pref_name_test = 0;
       for my $row (@$pref_list){
           isa_ok $row ,'HASH', 'a hash in a list in a array';
           my $pref_name = [keys %$row]->[0];
           if($pref_name eq '東京'){
               $pref_name_test = 1 if $row->{$pref_name} == 16;
           }
       }
       ok $pref_name_test, 'tokyo found';
    };

    subtest 'area_id_from_pref_id' => sub {
        is $tenki->area_id_from_pref_id(16), 3, 'tokyo is in kantou-koushin';
        is $tenki->area_id_from_pref_id(44), 9, 'saga is in kyusyu';
    };

    subtest 'get_image' => sub {
        my $image = $tenki->get_image( pref => 16 );
        ok $image, 'get image contents';
        like $image, qr/^\xFF\xD8/, 'image is jpg';
    };

    subtest 'get_image_with_date' => sub  {
        my $image = $tenki->get_image( pref => 16, date => '2015-05-12 20:00:00' );
        ok $image, 'get image contents';
        like $image, qr/^\xFF\xD8/, 'image is jpg';
    };
}

done_testing();
