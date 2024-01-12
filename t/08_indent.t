use strict;
use warnings;

use Test2::V0;

use Web::Query;

plan tests => 2;

my $inner = "<head></head><body><p>Hi there</p></body>";
my $html = "<html>$inner</html>";

is( Web::Query->new($html)->html => $inner, "no indent" );

like( Web::Query->new($html, { indent => "\t" } )->html => qr/\t/, "indented" );
