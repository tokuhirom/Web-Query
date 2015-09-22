use strict;
use warnings;

use Test::More;

use lib 't/lib';

use WQTest;

WQTest::test {
    my $class = shift;
    
    my $html = <<HTML;
    <div class="container">
      <div class="inner">Hello</div>
    </div>
    
    <div>
      <div class="inner">Hello</div>
    </div>
HTML

    my $q = $class->new($html);
    
    is $q->filter('span')->size, 0;
    is $q->filter('div.container')->size, 1;
    is $q->filter('div')->size, 2;

}
