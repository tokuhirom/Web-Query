use strict;
use warnings;

use Test::More;

my @modules = qw/ Web::Query Web::Query::LibXML /;

plan tests => scalar @modules;

for my $module ( @modules ) {
    subtest $module => sub {
        eval "require $module; 1" 
            or plan skip_all => "couldn't load $module";

        my $wq = $module->new_from_html(<<'END');
        <div><p><b>hello</b></p><p>there</p></div>
END

        is $wq->find('b')->html => 'hello', 'css';
        is $wq->find('//b')->text => 'hello', 'xpath';
    };
}
