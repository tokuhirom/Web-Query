use Test2::V0;
use Test2::Tools::Exception qw/dies/;

use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use Web::Query;

my $ua = $Web::Query::UserAgent = LWP::UserAgent->new( agent => 'Mozilla/5.0' );

$ua->add_handler(request_send => sub {
    my ($request) = @_;
    my $code = $request->uri->host eq 'bad.com' ? 500 : 200;
    return HTTP::Response->new($code);
});

plan tests => 2;

ok dies {
    Web::Query->new('http://bad.com/');
}, "without options";

ok dies {
    Web::Query->new('http://bad.com/',{indent=>3});
}, "with options";


