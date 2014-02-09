use strict;
use warnings;

use Test::More;
use Web::Query;

test('Web::Query');
test('Web::Query::LibXML') if eval "require Web::Query::LibXML; 1";

done_testing;

    
sub test {
    my $class = shift;    
    diag "testing $class";
    no warnings 'redefine';
    *wq = \&{$class . "::wq" };

    my $html = "<div><p>foo</p></div><div><p>bar</p></div><div><span>baz</span></div>";    
    
    is join('|', wq($html)->contents->as_html), '<p>foo</p>|<p>bar</p>|<span>baz</span>', 'contents()';    
    is join('|', wq($html)->contents('p')->as_html), '<p>foo</p>|<p>bar</p>', 'contents("p")';

    is wq('<p>foo</p>')->contents->as_html => 'foo';
}
