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

    my $html = <<HTML;
    <div class="container">
      <div class="inner">Hello</div>
    </div>
    
    <div>
      <div class="inner">Hello</div>
    </div>
HTML
    
    is wq($html)->filter('span')->size, 0;
    is wq($html)->filter('div.container')->size, 1;
    is wq($html)->filter('div')->size, 2;

}