use strict;
use warnings;
use utf8;
use Test::More;
use Web::Query qw/wq/;

my $html = <<'...';
<html><body><div id="foo"><div id="bar"><div id="baz"></div></div></div></body></html>
...
subtest 'parent' => sub {
    is wq($html)->find('#baz')->parent()->attr('id'), 'bar';
    is wq($html)->find('#bar')->parent()->attr('id'), 'foo';
};
subtest 'size' => sub {
    is wq($html)->find('div')->size,  3;
    is wq($html)->find('body')->size, 1;
    is wq($html)->find('li')->size,   0;
    is wq($html)->find('.null')->first->size, 0;
    is wq($html)->find('.null')->last->size,  0;
};

done_testing;

