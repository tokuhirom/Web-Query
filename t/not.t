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
    *wq = \&{$class . "::wq" };

    my $wq = wq(<<HTML);
    <div>
        <p id="first">one</p>
        <p id="second">two</p>
        <p>three</p>
    </div>
    
HTML
    
    is $wq->find('p')->not( '#second' )->size => 2;

}
