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

    my $wq = wq('<div class="container"><div class="inner foo bar">Hello</div><div class="inner foo bar">Goodbye</div></div>');    
    my $rv = $wq->find('.inner')->remove_class('foo bar');
    
    isa_ok $rv, 'Web::Query', 'remove_class returned';
    is $wq->as_html, '<div class="container"><div class="inner">Hello</div><div class="inner">Goodbye</div></div>', 'remove_class("foo bar")';
    
    $wq = wq('<div class="container"><div class="inner foo bar">Hello</div><div class="inner foo bar">Goodbye</div></div>');    
    $wq->find('.inner')->remove_class(sub{ 'foo bar' });
    
    is $wq->as_html, '<div class="container"><div class="inner">Hello</div><div class="inner">Goodbye</div></div>', 'remove_class(CODE)';

}