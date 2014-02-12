use strict;
use warnings;
use Test::More;

my @modules = qw/ Web::Query Web::Query::LibXML /;

plan tests => scalar @modules;

subtest $_ => sub { test($_) } for @modules;

sub test {
    my $class = shift;

    eval "require $class; 1" 
        or plan skip_all => "couldn't load $class";

    no warnings 'redefine';
    *wq = \&{$class . "::wq" };
    
    my $html = '<p><b>Hi</b><i>there</i><u>world</u></p>';

    is wq($html)->find('b')->replace_with('<strong>Hello</strong>')->end->as_html
        => '<p><strong>Hello</strong><i>there</i><u>world</u></p>';
    
    my $q = wq( $html );
    
    is $q->find('u')->replace_with($q->find('b'))->end->as_html
        => '<p><i>there</i><b>Hi</b></p>';
    
    is wq($html)->find('*')->replace_with(sub {
        my $i = $_->text;
        return "<$i></$i>";
    } )->end->as_html => '<p><hi></hi><there></there><world></world></p>';
    
    is wq($html)->find('*')->replace_with( '<blink />' )->end->as_html
        => '<p><blink></blink><blink></blink><blink></blink></p>';    

    is wq('<p><span>foo</span></p>')->find('span')
        ->replace_with(sub { $_->contents })
        ->end->as_html => '<p>foo</p>';
}
