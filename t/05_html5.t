use strict;
use warnings;
use utf8;
use Test::More;
use Web::Query qw/wq/;

is(wq('<html><header>foo</header></html>')->find('header')->first->text, 'foo');

done_testing;

