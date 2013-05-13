use strict;
use warnings;

use Test::More tests => 3;

use Web::Query;

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

