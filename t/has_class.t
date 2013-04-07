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

is $wq->find('.inner')->has_class('inner'), 1, 'has_class - positive';
is $wq->find('.inner')->has_class('nahh'), undef, 'has_class - negative';

done_testing;
