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
    
    is $wq->find('.inner')->has_class('inner'), 1, 'has_class - positive';
    is $wq->find('.inner')->has_class('nahh'), undef, 'has_class - negative';
}
