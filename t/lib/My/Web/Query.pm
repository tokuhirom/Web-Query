package My::Web::Query;

use strict;
use warnings;
use parent qw/Web::Query Exporter/;
use My::TreeBuilder;

our @EXPORT = qw/wq/;

sub wq { My::Web::Query->new(@_) }

sub _build_tree {
    my ($self, $content) = @_;    
    my $tree = My::TreeBuilder->new();
    $tree->ignore_unknown(0);
    $tree->store_comments(1);
    $tree;    
}