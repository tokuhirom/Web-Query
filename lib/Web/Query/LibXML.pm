package Web::Query::LibXML;
our $AUTHORITY = 'cpan:TOKUHIROM';
# ABSTRACT: fast, drop-in replacement for Web::Query
$Web::Query::LibXML::VERSION = '0.34';

use 5.008005;
use strict;
use warnings;
use parent qw/Web::Query Exporter/;
use HTML::TreeBuilder::LibXML;

# version required for unique_key
use XML::LibXML 2.0107;

our @EXPORT = qw/wq/;

sub wq { Web::Query::LibXML->new(@_) }

sub _build_tree {
    my $tree = HTML::TreeBuilder::LibXML->new();
    $tree->ignore_unknown(0);
    $tree->store_comments(1);
    $tree;    
}

sub _is_same_node {
    $_[1]->{node}->isSameNode($_[2]->{node});
}

sub prev {
    my $self = shift;
    my @new;
    for my $tree (@{$self->{trees}}) {
        push @new, $tree->left;
    }
    return (ref $self || $self)->new_from_element(\@new, $self);
}

sub next {
    my $self = shift;
    my @new;
    for my $tree (@{$self->{trees}}) {
        push @new, grep { $_ } $tree->right;
    }
    return (ref $self || $self)->new_from_element(\@new, $self);
}

sub tagname {
    my $self = shift;
    my $method = @_ ? 'setNodeName' : 'nodeName';
    
    my @retval = map { $_->{node}->$method(@_) } @{$self->{trees}};
    return wantarray ? @retval : $retval[0];
}

sub _node_id { $_[1]{node}->unique_key }
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Web::Query::LibXML - fast, drop-in replacement for Web::Query

=head1 VERSION

version 0.34

=head1 SYNOPSIS

    use Web::Query::LibXML; 
    
    # imports wq()
    # all methods inherited from Web::Query
    # see Web::Query for documentation  

=head1 DESCRIPTION

Web::Query::LibXML is Web::Query subclass that overrides the _build_tree() method to use HTML::TreeBuilder::LibXML instead of HTML::TreeBuilder::XPath.
Its a lot faster than its superclass. Use this module unless you can't install (or depend on) L<XML::LibXML> on your system.

=head1 FUNCTIONS

=over 4

=item C<< wq($stuff) >>

This is a shortcut for C<< Web::Query::LibXML->new($stuff) >>. This function is exported by default.

=back

=head1 METHODS

All public methods are inherited from L<Web::Query>.

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@q1software.comE<gt>

=head1 SEE ALSO

L<Web::Query>, L<HTML::TreeBuilder::LibXML>, L<XML::LibXML> 

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/tokuhirom/Web-Query/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
