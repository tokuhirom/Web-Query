use strict;
use warnings;

use Test2::V0;

use lib 't/lib';

use WQTest;

WQTest::test {
    my $class = shift;

    subtest 'create an empty $q' => sub {
        my $new = $class->new;

        $new = $new->add( '<p>something</p>' );

        is $new->as_html => '<p>something</p>';
    };
}
