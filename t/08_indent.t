use strict;
use warnings;

use Test::More tests => 2;
use Web::Query;

my $inner = "<head></head><body><p>Hi there</p></body>";
my $html = "<html>$inner</html>";

is( Web::Query->new($html)->html => $inner, "no indent" );

like( Web::Query->new($html, { indent => "\t" } )->html => qr/\t/, "indented" );
