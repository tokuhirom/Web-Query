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

subtest 'bad status code' => sub {
    my $q = wq('http://bad.com/');
    is($q, undef);

    isa_ok($Web::Query::RESPONSE, 'HTTP::Response');
    is($Web::Query::RESPONSE->code, 500);

    isa_ok(Web::Query->last_response, 'HTTP::Response');
    is(Web::Query::last_response->code, 500);
};
subtest 'good status code' => sub {
    my $q = wq('http://good.com/');
    ok($q);

    isa_ok($Web::Query::RESPONSE, 'HTTP::Response');
    is($Web::Query::RESPONSE->code, 200);

    isa_ok(Web::Query->last_response, 'HTTP::Response');
    is(Web::Query::last_response->code, 200);
};

done_testing;

