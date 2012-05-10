use inc::Module::Install;
name 'WebService-TenkiJp-Radar-Image';
all_from 'lib/WebService/TenkiJp/Radar/Image.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
