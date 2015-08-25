use strict;
use warnings;

use Test::More;

use lib 't/lib';

use WQTest;

WQTest::test {
    my $class = shift;

    my $wq = $class->new_from_html( '<div><foo></foo></div>', { indent => "\t" } );
    $wq->find('foo')->remove;

    is $wq->as_html => '<div></div>';

    for my $method ( qw/ each map / ) {
        subtest $method => sub {
            plan tests => 5;

            my $wq = new_wq($class);

            $wq->find('p')->$method(sub{
                pass "deleting " . $_->text;
                $_->remove;
            });

            is $wq->find('p')->size => 0, "all deleted";
        };
    }
};

sub new_wq {
    shift->new(<<'END');
        <div>
            <p>one</p>
            <p>two</p>
            <p>three</p>
            <p>four</p>
        </div>
END
}
