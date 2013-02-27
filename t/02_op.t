use strict;
use warnings;
use utf8;
use Test::More;
use Web::Query;

subtest 'get/set text' => sub {
    my $q = wq('t/data/foo.html');
    $q->find('.foo a')->text('> ok');
    is trim($q->find('.foo a')->text()), '> ok';
    is trim($q->find('.foo a')->html()), '&gt; ok';
};

subtest 'get/set html' => sub {
    my $q = wq('t/data/foo.html');
    $q->find('.foo')->html('<B>ok</B>');
    is trim($q->find('.foo')->html()), '<b>ok</b>';
};

done_testing;

sub trim {
    local $_ = shift;
    $_ =~ s/[\r\n]+$//;
    $_
}
