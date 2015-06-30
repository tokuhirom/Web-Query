use strict;
use warnings;

use Test::More;

use lib 't/lib';

use WQTest;

WQTest::test(sub{
    my $class = shift;

    my $wq = $class->new_from_html( '<div><foo></foo></div>', { indent => "\t" } );
    $wq->find('foo')->remove;

    is $wq->as_html => '<div></div>';
});
