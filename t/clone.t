use strict;
use warnings;
use Test::More;
use Web::Query;

my $html = '<p><b>Hi</b><i>there</i><u>world</u></p>';

is wq($html)->clone->as_html, $html, 'clone';

done_testing;
