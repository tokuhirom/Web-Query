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

    my $wq = wq('<div class="container"><div class="inner"><p>Hello</p></div><div class="inner"><p>Goodbye</p></div></div>');
    
    my $detached = $wq->find('.inner')->detach;
    is join('', $detached->as_html), '<div class="inner"><p>Hello</p></div><div class="inner"><p>Goodbye</p></div>', 'detach - retval';
    is $wq->as_html, '<div class="container"></div>', 'detach - original object modified';
    is $detached->find('p')->size, 2, 'find() works on detached elements';

}
