use strict;
use warnings;

use Test::More tests => 4;
use FindBin;
use lib 'lib';
use lib "$FindBin::Bin/lib";

BEGIN { use_ok 'My::Web::Query' }

# web::query is a child class friendly
my $query = wq('<div>foo</div>');

isa_ok $query, 'My::Web::Query', 'object from wq()';

$query->each(sub{
    isa_ok $_[1], 'My::Web::Query', 'object from each()';    
});

isa_ok $query->_build_tree, 'My::TreeBuilder', '_build_tree()';
