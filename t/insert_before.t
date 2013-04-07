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

wq('<p>Test</p>')->insert_before($wq->find('.inner'));

is $wq->as_html, '<div class="container"><p>Test</p><div class="inner">Hello</div><p>Test</p><div class="inner">Goodbye</div></div>', 'insert_before';

done_testing;