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
    
    my $html = '<html><body><ul id="foo"><li>A</li><li>B</li><li>C</li><li>D</li><li>E</li><li>F</li></ul></body></html>';
    
    subtest 'first' => sub {
        is wq($html)->find('#foo li')->first()->text(), 'A';
    };
    subtest 'last' => sub {
        is wq($html)->find('#foo li')->last()->text(), 'F';
    };

}
