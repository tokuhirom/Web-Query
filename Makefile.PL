use inc::Module::Install;
use Module::Install::AuthorTests;

name 'Web-Query';
all_from 'lib/Web/Query.pm';

requires 'HTML::TreeBuilder::XPath' => 0.12;
requires 'HTML::Selector::XPath'    => 0.06;
requires 'LWP::UserAgent'           => 5.385;
requires 'parent';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');
WriteAll;
