use strict;
use warnings;
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

    my $wq = wq(<<HTML);

    <div class="container">
      <div class="d1">Hello</div>
      <div class="d2">World</div>
    </div>

    <div class="container">
      <div class="d1">Hello</div>
      <div class="d2">World</div>
    </div>
HTML

    my $elem = $wq->find('.d1')->next;
    is $elem->size, 2;
    is $elem->attr('class'), 'd2', 'next';

    subtest 'next->as_html' => sub {
        plan tests => 6;

        $wq = wq( q{
            <div>
                <b>one</b>
                two
                <i>three</i></div>
        } );

        my @expected = (
            [ b       => qr/one/ ],
            [ '#text' => qr/two/ ],
            [ 'i'     => qr/three/ ],
        );

        my $next = $wq->find('b');
        while( $next->size ) {
            my $exp = shift @expected;
            is $next->tagname => $exp->[0], 'tagname';
            like $next->as_html => $exp->[1], 'as_html';
            $next = $next->next;
        };
    };
}
