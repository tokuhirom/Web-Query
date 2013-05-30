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
    
    my $wq = wq($html);
    
    $wq->find('.inner')->add_class('foo bar inner');    
    is $wq->as_html, '<div class="container"><div class="inner foo bar">Hello</div><div class="inner foo bar">Goodbye</div></div>', 'add_class("foo bar inner")';
    
    # add_class(CODE)
    $wq = wq($html);
    
    $wq->find('.inner')->add_class(sub{
        my ($i, $current, $el) = @_;
        return "foo-$i bar";
    });
    
    is $wq->as_html, '<div class="container"><div class="inner foo-0 bar">Hello</div><div class="inner foo-1 bar">Goodbye</div></div>', 'add_class(CODE)';

}
