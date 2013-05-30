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
    

    my $source = '<div><!-- header --><header></header></div>';
    
    is join('', wq($source)->as_html), $source, 'constructor stores comments';
    
    is wq($source)->find('header')->html('<p><!-- comment --></p>')->as_html, '<header><p><!-- comment --></p></header>', 'html() stores comments';

}