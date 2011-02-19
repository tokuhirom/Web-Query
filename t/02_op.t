use strict;
use warnings;
use utf8;
use Test::More;
use Web::Query;

subtest 'get/set text' => sub {
    my $q = wq('t/data/foo.html');
    $q->find('.foo a')->text('> ok');
    is $q->find('.foo a')->text(), '> ok';
    is $q->find('.foo a')->html(), '<a href="/foo">&gt; ok</a>';
};

subtest 'get/set html' => sub {
    my $q = wq('t/data/foo.html');
    $q->find('.foo')->html('<B>ok</B>');
    is $q->find('.foo')->html(), '<div class="foo"><b>ok</b></div>';
};

done_testing;

