package WQTest;

use strict;
use warnings;

use Test::More;

sub test(&) {
    my $code = shift;

    plan tests => 3;

    use_ok 'Web::Query';

    for my $class ( qw/ Web::Query Web::Query::LibXML / ) {
        subtest $class => sub {
            if( $class =~ /LibXML/ ) {
                plan skip_all => "can't load $class" unless eval "use $class; 1";
            }

            $code->($class, \&{$class . "::wq" });
    };
}

}

1;
