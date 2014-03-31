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
    *wq = \&{$class . "::wq"};

    my $wq = wq(<<HTML);

    <div class="container">
      <div class="d1">Hello</div>
      <div class="d2">World</div>
    </div>

    <div class="container">
      <div class="d1">Hello</div>
      <div class="d2">World</div>
    </div>
HTML

    my $elem = $wq->find('.d2')->prev;
    is $elem->size, 2;
    is $elem->attr('class'), 'd1', 'previous';
}
