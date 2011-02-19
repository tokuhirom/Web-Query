use inc::Module::Install;
use Module::Install::AuthorTests;

name 'Web-Query';
all_from 'lib/Web/Query.pm';

requires 'HTML::TreeBuilder::XPath';
requires 'HTML::Selector::XPath';
requires 'LWP::UserAgent' => 5.385;
requires 'parent';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More' => 0.96; # done_testing, subtest
author_tests('xt');
WriteAll;
