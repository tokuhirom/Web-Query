use strict;
use warnings;
use utf8;
use Test::More;
use Web::Query;

test('Web::Query');
test('Web::Query::LibXML') if eval "require Web::Query::LibXML; 1";

done_testing;

    
sub test {
    my $class = shift;    
    diag "testing $class";
    no warnings 'redefine';
    *wq = \&{$class . "::wq" };

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

}

sub trim {
    local $_ = shift;
    $_ =~ s/[\r\n]+$//;
    $_
}
