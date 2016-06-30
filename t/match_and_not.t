use strict;
use warnings;

use Test::More;

use lib 't/lib';

use WQTest;

WQTest::test {
    my $class = shift;
    
    my $wq = $class->new(<<HTML);
    <div>
        <p id="first" class="foo">one</p>
        <p id="second">two</p>
        <p class="foo">three</p>
    </div>
    
HTML
    
    is $wq->find('p')->not( '#second' )->size => 2, 'not';
    is $wq->find('p')->filter( '#second' )->size => 1, 'filter';

    subtest 'match' => sub {
        is_deeply [ $wq->find('p')->match( '.foo' ) ], [ 1, '', 1 ], "list context";
        is scalar $wq->find('p')->match( '.foo' ) =>  1, "scalar context";
    };

}
