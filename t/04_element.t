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

done_testing;
