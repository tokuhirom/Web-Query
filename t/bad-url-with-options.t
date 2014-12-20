use strict;
use warnings;
use utf8;
use Test::More;
use LWP::UserAgent;
use Web::Query;

my $ua = LWP::UserAgent->new( agent => 'Mozilla/5.0' );
$Web::Query::UserAgent = $ua;
$ua->add_handler(request_send => sub {
    my ($request, $ua, $h) = @_;
    if ($request->uri->host eq 'bad.com') {
        return HTTP::Response->new(500);
    } else {
        return HTTP::Response->new(200);
    }
});

plan tests => 2;

is( Web::Query->new('http://bad.com/'), undef, 'without options' );

is( Web::Query->new('http://bad.com/', { indent => 3 }) => undef, 'with options' );

