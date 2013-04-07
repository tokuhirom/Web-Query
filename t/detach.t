#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use Web::Query;

my $wq = wq(<<HTML);
<div class="container">
  <div class="inner">Hello</div>
  <div class="inner">Goodbye</div>
</div>
HTML

my $detached = $wq->find('.inner')->detach;
is join('', $detached->as_html), '<div class="inner">Hello</div><div class="inner">Goodbye</div>', 'detach - retval';
is $wq->as_html, '<div class="container"></div>', 'detach - original object modified';
is $detached->find('.inner')->size, 2, 'detached can find() root elements';

done_testing;