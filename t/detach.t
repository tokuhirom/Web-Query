#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use Web::Query;

my $wq = wq(<<HTML);
<div class="container">
  <div class="inner"><p>Hello</p></div>
  <div class="inner"><p>Goodbye</p></div>
</div>
HTML

my $detached = $wq->find('.inner')->detach;
is join('', $detached->as_html), '<div class="inner"><p>Hello</p></div><div class="inner"><p>Goodbye</p></div>', 'detach - retval';
is $wq->as_html, '<div class="container"></div>', 'detach - original object modified';
is $detached->find('p')->size, 2, 'find() works on detached elements';

done_testing;