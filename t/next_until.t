use strict;
use warnings;

use Test::More;

use Test::More;
use Web::Query;

test('Web::Query');
test('Web::Query::LibXML') if eval "require Web::Query::LibXML; 1";

done_testing;

sub test {
    my $class = shift;
    diag "testing $class";
    no warnings 'redefine';
    *wq = \&{$class . "::wq"};

    my $wq = wq(q{
        <div>
            <h1 id="first">one</h1>
            <h2>two</h2>
            <h2>three</h2>
            <h1 id="second">four</h1>
            <h2>five</h2>
            <h2>six</h2>
        </div>
    });

    for my $id ( qw/ first second / ) {
        my $next = $wq->find('#'.$id)->next_until('h1');
        is $next->size => 2;
    }

    is $wq->find('#first')->next_until('h1')->and_back->size  => 3, "and_back";

    is $wq->find('h1')->next_until('h1')->size => 4;
    is $wq->find('h1')->next_until('foo')->size => 5;
}
