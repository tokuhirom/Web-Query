use strict;
use warnings;

use Test::More tests => 3;

use Web::Query;

my $wq = wq(<<HTML);

<div class="container">
  <div class="inner">Hello</div>
</div>

<div class="container">
  <div class="inner">Hello</div>
</div>

HTML

is $wq->find('.inner')->size, 2, 'find() on multiple tree object';

is wq('<html>1</html>')->find('html')->size, 0, 'find() includes root elements';
is(wq('<div>foo</div><div>bar</div>')->find('div')->size, 0);

