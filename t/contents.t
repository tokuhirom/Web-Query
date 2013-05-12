use strict;
use warnings;

use Test::More;
use Web::Query;

my $html = "<div><p>foo</p></div><div><p>bar</p></div><div><span>baz</span></div>";

is join('|', wq($html)->contents->as_html), '<p>foo</p>|<p>bar</p>|<span>baz</span>', 'contents()';

is join('|', wq($html)->contents('p')->as_html), '<p>foo</p>|<p>bar</p>', 'contents("p")';



done_testing;