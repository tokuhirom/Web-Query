#!/usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use Test2::V0;
use Web::Query ();

my $wq = Web::Query->new('<html><body></body></html>');
local $@ = 'foo';
$wq->DESTROY;
is $@, 'foo', 'eval error string should not be clobbered';

done_testing;
