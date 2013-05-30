#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
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


    my $html = '<div class="container"><div class="inner">Hello</div><div class="inner">Goodbye</div></div>';
    
    is wq($html)->find('.inner')->prepend('<p>Test</p>')->end->as_html, 
        '<div class="container"><div class="inner"><p>Test</p>Hello</div><div class="inner"><p>Test</p>Goodbye</div></div>', 'prepend';

}