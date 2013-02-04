use strict;
use warnings;

use Test::More tests => 2;
use Web::Query;

my $html = "<html><head></head><body><p>Hi there</p></body></html>";

is( Web::Query->new($html)->html => $html, "no indent" );

like( Web::Query->new($html, { indent => "\t" } )->html => qr/\t/, "indented" );



