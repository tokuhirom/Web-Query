use strict;
use warnings;

use Test::More;

use lib 't/lib';

use WQTest;

WQTest::test {
    my $class = shift;
    
    my $wq = $class->new(<<HTML);
    <div>
        <p id="first">one</p>
        <p id="second">two</p>
        <p>three</p>
    </div>
    
HTML
    
    is $wq->find('p')->not( '#second' )->size => 2, 'not';
    is $wq->find('p')->match( '#second' )->size => 1, 'match';

}
