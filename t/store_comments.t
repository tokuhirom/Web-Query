use strict;
use warnings;
use Test::More;
use Web::Query;

my $source = '<div><!-- header --><header></header></div>';

is join('', wq($source)->as_html), $source, 'constructor stores comments';

is wq($source)->find('header')->html('<!-- comment -->')->as_html, '<header><!-- comment --></header>', 'html() stores comments';


done_testing;