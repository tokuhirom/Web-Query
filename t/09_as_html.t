use strict;
use warnings;

use Test::More tests => 4;
use Web::Query;

my $inner = "<head></head><body><p>Hi there</p><p>How is life?</p></body>";
my $html = "<html>$inner</html>";

my $q = Web::Query->new($html);

is $q->html => $inner, "html() returns inner html";
is $q->as_html => $html, "as_html() returns element itself";

my $scalar = $q->find('p')->as_html;
my @array = $q->find('p')->as_html;

is $scalar => '<p>Hi there</p>', 'called in scalar context';
is_deeply \@array => [ '<p>Hi there</p>', q{<p>How is life?</p>} ],
    'called in list context';




