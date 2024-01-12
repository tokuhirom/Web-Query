use strict;
use warnings;

use Test2::V0; plan tests => 3;
use FindBin;
use lib 'lib';
use lib "$FindBin::Bin/lib";

use My::Web::Query;

# web::query is a child class friendly
my $query = wq('<div>foo</div>');

isa_ok $query, 'My::Web::Query';

$query->each(sub{
    isa_ok $_[1], 'My::Web::Query';    
});

isa_ok $query->_build_tree, 'My::TreeBuilder';
