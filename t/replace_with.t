use strict;
use warnings;

use Test::More tests => 4;

use Web::Query;

my $html = '<p><b>Hi</b><i>there</i><u>world</u></p>';

is wq($html)->find('b')->replace_with('<strong>Hello</strong>')->end->as_html
    => '<p><strong>Hello</strong><i>there</i><u>world</u></p>';

my $q = wq( $html );

is $q->find('u')->replace_with($q->find('b'))->end->as_html
    => '<p><i>there</i><b>Hi</b></p>';

is wq($html)->find('p *')->replace_with(sub {
    my $i = $_->text;
    return "<$i></$i>";
} )->end->as_html => '<p><hi></hi><there></there><world></world></p>';

is wq($html)->find('p *')->replace_with( '<blink />' )->end->as_html
    => '<p><blink></blink><blink></blink><blink></blink></p>';
