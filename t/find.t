use strict;
use warnings;

use Test::More tests => 2;

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

is wq('<html>1</html>')->find('html')->size, 1, 'find() includes root elements';

