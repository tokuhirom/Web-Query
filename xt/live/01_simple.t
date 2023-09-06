use strict;
use warnings;
use utf8;
use Test::More;
use Web::Query;

binmode Test::More->builder->$_, ":utf8" for qw/output failure_output todo_output/;                       

my @res;
wq('https://techblog.babyl.ca/')
  ->find('div')
  ->each(sub {
        my $i = shift;
        push @res, $_->text;
        note(sprintf "%d) %s\n", $i+1, $_->text)
  });

ok @res;

done_testing;
