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
    
    <div class="container">
      <div class="inner">Hello</div>
    </div>
    
    <div class="container">
      <div class="inner">Hello</div>
    </div>
    
HTML
    
    is $wq->find('.inner')->size, 2, 'find() on multiple tree object';
    
    is wq('<html>1</html>')->find('html')->size, 0, 'find() does not include root elements';
    is(wq('<div>foo</div><div>bar</div>')->find('div')->size, 0);

}
