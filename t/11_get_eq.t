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
    
    subtest 'get first' => sub {
        my $q = wq($html)->find('#foo li');
        my $elm = $q->get(0);
        isa_ok $elm, 'HTML::Element';
        is wq($elm)->text(), 'A';
    };
    subtest 'get second' => sub {
        my $q = wq($html)->find('#foo li');
        my $elm = $q->get(1);
        isa_ok $elm, 'HTML::Element';
        is wq($elm)->text(), 'B';
    };
    subtest 'get last' => sub {
        my $q = wq($html)->find('#foo li');
        my $elm = $q->get(-1);
        isa_ok $elm, 'HTML::Element';
        is wq($elm)->text(), 'F';
    };
    subtest 'get before last' => sub {
        my $q = wq($html)->find('#foo li');
        my $elm = $q->get(-2);
        isa_ok $elm, 'HTML::Element';
        is wq($elm)->text(), 'E';
    };

    subtest 'eq first' => sub {
        is wq($html)->find('#foo li')->eq(0)->text(), 'A';
    };
    subtest 'eq second' => sub {
        is wq($html)->find('#foo li')->eq(1)->text(), 'B';
    };
    subtest 'eq last' => sub {
        is wq($html)->find('#foo li')->eq(-1)->text(), 'F';
    };
    subtest 'eq before last' => sub {
        is wq($html)->find('#foo li')->eq(-2)->text(), 'E';
    };

}
