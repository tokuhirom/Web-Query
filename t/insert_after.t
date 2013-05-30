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

    my $wq = wq('<div class="container"><div class="inner">Hello</div><div class="inner">Goodbye</div></div>');
        
    wq('<p>Test</p>')->insert_after($wq->find('.inner'));    
    is $wq->as_html, '<div class="container"><div class="inner">Hello</div><p>Test</p><div class="inner">Goodbye</div><p>Test</p></div>', 'insert_after';    
}