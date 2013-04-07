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

$wq->find('.inner')->add_class('foo bar inner');
#diag $wq->as_html;
is $wq->as_html, '<div class="container"><div class="inner foo bar">Hello</div><div class="inner foo bar">Goodbye</div></div>', 'add_class("foo bar inner")';


$wq = wq(<<HTML);
<div class="container">
  <div class="inner">Hello</div>
  <div class="inner">Goodbye</div>
</div>
HTML

$wq->find('.inner')->add_class(sub{
    my ($i, $current, $el) = @_;
    return "foo-$i bar";
});

is $wq->as_html, '<div class="container"><div class="inner foo-0 bar">Hello</div><div class="inner foo-1 bar">Goodbye</div></div>', 'add_class(CODE)';

done_testing;
