use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Web::Query;

use WQTest;

my $doc = <<'END';
<div>
    <p>stuff</p>
    <h1>alpha</h1>
        <p>aaa</p>
    <h1>beta></h1>
    <h1>gamma</h1>
        <p>bbb<p>
        <p>ccc</p>
</div>
END

WQTest::test {
    my $class = shift;    

    subtest 'straight split' => sub {
        my @splitted = $class->new($doc)->split( 'h1' );

        is scalar @splitted => 4;
        like $splitted[0]->as_html(join => ''), 
            qr/stuff/;
        like $splitted[1]->as_html(join => ''),
            qr/alpha.*aaa/s;
        like $splitted[2]->as_html(join => ''),
            qr/beta/;
        like $splitted[3]->as_html(join => ''),
            qr/gamma.*ccc/s;
    };

    subtest 'split in pairs' => sub {
        my @splitted = $class->new($doc)->split( 'h1', pairs => 1 );

        is scalar @splitted => 4;
        like $splitted[0][1]->as_html(join => ''), 
            qr/stuff/;
        like $splitted[1][0]->as_html(join => ''),
            qr/alpha/;
        like $splitted[1][1]->as_html(join => ''),
            qr/aaa/;
    };

    subtest 'skip leading' => sub {
        my @splitted = $class->new($doc)->split( 'h1', pairs => 1, skip_leading => 1 );

        is scalar @splitted => 3;
        like $splitted[0][0]->as_html( join => '' ),
            qr/alpha/;
        like $splitted[0][1]->as_html( join => '' ),
            qr/aaa/;
    };

}
