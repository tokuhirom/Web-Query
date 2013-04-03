package My::Web::Query;

use strict;
use warnings;
use parent qw/Web::Query Exporter/;

our @EXPORT = qw/wq/;

sub wq { My::Web::Query->new(@_) }
