use strict;
use warnings;
use utf8;
use Test::More;
use Web::Query qw/wq/;

my $html = <<'...';
<html><body><ul id="foo"><li>A</li><li>B</li><li>C</li><li>D</li><li>E</li><li>F</li></ul></body></html>
...
subtest 'first' => sub {
    is wq($html)->find('#foo li')->first()->text(), 'A';
};
subtest 'last' => sub {
    is wq($html)->find('#foo li')->last()->text(), 'F';
};
subtest 'slice' => sub {
    is wq($html)->find('#foo li')->slice(0)->text(), 'A';
    is wq($html)->find('#foo li')->slice(1)->text(), 'B';
    is wq($html)->find('#foo li')->slice(-1)->text(), 'F';
    is join(',', wq($html)->find('#foo li')->slice(1, 2)->text()), 'B,C';
    is join(',', wq($html)->find('#foo li')->slice(3, 5)->text()), 'D,E,F';
    is join(',', wq($html)->find('#foo li')->slice(1, 0)->text()), '';
};

done_testing;
