use strict;
use warnings;
use utf8;
use Test::More;
use Scalar::Util qw/refaddr/;
use Web::Query;

test('Web::Query');
test('Web::Query::LibXML') if eval "require Web::Query::LibXML; 1";

done_testing;

    
sub test {
    my $class = shift;    
    diag "testing $class";
    no warnings 'redefine';
    *wq = \&{$class . "::wq" };

    my $html = '<html><body><div id="foo"><div id="bar"><div id="baz"></div></div></div></body></html>';
    
    subtest 'parent' => sub {
        is wq($html)->find('#baz')->parent()->attr('id'), 'bar';
        is wq($html)->find('#bar')->parent()->attr('id'), 'foo';
    };
    
    subtest 'first/last return new instance' => sub {
        subtest 'first' => sub {
            my $q = wq($html)->find('div');
            my $first = $q->first;
            isnt(refaddr($first), refaddr($q));
        };
        subtest 'last' => sub {
            my $q = wq($html)->find('div');
            my $last = $q->last;
            isnt(refaddr($last), refaddr($q));
        };
    };
    subtest 'size' => sub {
        is wq($html)->find('div')->size,  3;
        is wq($html)->find('body')->size, 1;
        is wq($html)->find('li')->size,   0;
        is wq($html)->find('.null')->first->size, 0;
        is wq($html)->find('.null')->last->size,  0;
    };
    subtest 'map' => sub {
        is_deeply wq($html)->find('div')->map(sub {$_[0]}), [0, 1, 2];
        is_deeply wq($html)->find('div')->map(sub {$_->attr('id')}), [qw/foo bar baz/];
    };
    subtest 'filter' => sub {
        is wq($html)->filter('div')->size,                                          0;
        is wq($html)->filter('body')->size,                                         0;
        is wq($html)->filter('li')->size,                                           0;
        is wq($html)->find('div')->filter(sub {$_->attr('id') =~ /ba/})->size,      2;
        is wq($html)->find('div')->filter(sub {my $i = shift; $i % 2 == 0})->size,  2;
    };
}

