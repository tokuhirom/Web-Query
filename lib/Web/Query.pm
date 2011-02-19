package Web::Query;
use strict;
use warnings;
use 5.008001;
use parent qw/Exporter/;
our $VERSION = '0.01';
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;
use HTML::Selector::XPath 0.06 qw/selector_to_xpath/;
use Scalar::Util qw/blessed/;

our @EXPORT = qw/wq/;

sub wq { Web::Query->new(@_) }

our $UserAgent = LWP::UserAgent->new();

sub __ua {
    $UserAgent ||= LWP::UserAgent->new( agent => __PACKAGE__ . "/" . $VERSION );
    $UserAgent;
}

sub new {
    my ($class, $stuff) = @_;
    if (ref $stuff eq 'ARRAY') {
        return $class->new_from_trees($stuff);
    } elsif (blessed $stuff) {
        return $class->new_from_trees([$stuff]);
    } if (!ref $stuff && $stuff =~ m{^(?:https?|file)://}) {
        return $class->new_from_url($stuff);
    } elsif (!ref $stuff && $stuff =~ /<html/i) {
        return $class->new_from_html($stuff);
    } elsif (!ref $stuff && $stuff !~ /\n/ && -f $stuff) {
        return $class->new_from_file($stuff);
    } else {
        die "Unknown source type: $stuff";
    }
}

sub new_from_url {
    my ($class, $url) = @_;
    my $res = __ua()->get($url);
    die $res->status_line unless $res->is_success;
    return $class->new_from_html($res->decoded_content);
}

sub new_from_file {
    my ($class, $fname) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_file($fname);
    my $self = $class->new_from_trees([$tree->elementify]);
    $self->{need_delete}++;
    return $self;
}

sub new_from_html {
    my ($class, $html) = @_;
    my $tree = HTML::TreeBuilder::XPath->new();
    $tree->parse_content($html);
    my $self = $class->new_from_trees([$tree->elementify]);
    $self->{need_delete}++;
    return $self;
}

sub new_from_trees {
    my $class = shift;
    my $trees = ref $_[0] eq 'ARRAY' ? $_[0] : +[$_[0]];
    return bless { trees => $trees, before => $_[1] }, $class;
}

sub end {
    my $self = shift;
    return $self->{before};
}

sub find {
    my ($self, $selector) = @_;
    my @new;
    for my $tree (@{$self->{trees}}) {
        $selector = selector_to_xpath($selector, root => './');
        push @new, $tree->findnodes($selector);
    }
    return Web::Query->new_from_trees(\@new, $self);
}

sub html {
    my ($self) = @_;
    my @html = map { $_->as_HTML(q{&<>'"}) } @{$self->{trees}};
    return wantarray ? @html : $html[0];
}

sub text {
    my $self = shift;
    my @html = map { $_->as_text } @{$self->{trees}};
    return wantarray ? @html : $html[0];
}

sub attr {
    my $self = shift;
    my @retval = map { $_->attr(@_) } @{$self->{trees}};
    return wantarray ? @retval : $retval[0];
}

sub each {
    my ($self, $code) = @_;
    my $i = 0;
    for my $tree (@{$self->{trees}}) {
        local $_ = wq($tree);
        $code->($i++, $_);
    }
    return $self;
}

sub DESTROY {
    if ($_[0]->{need_delete}) {
        $_->delete for @{$_[0]->{trees}}; # avoid memory leaks
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Web::Query - Yet another scraping library like jQuery

=head1 SYNOPSIS

    use Web::Query;

    wq('http://google.com/search?q=foobar')
          ->find('h2')
          ->each(sub {
                my $i = shift;
                printf("%d) %s\n", $i+1, wq($_)->text
          });

=head1 DESCRIPTION

Web::Query is a yet another scraping framework, have a jQuery like interaface.

Yes, I know ingy's pQuery. But it's just a alpha quality. It doesn't works.
Web::Query built at top of the CPAN modules, L<HTML::TreeBuilder::XPath>, L<LWP::UserAgent>, and L<HTML::Selector::XPath>.

So, this module uses L<HTML::Selector::XPath>, then this module only supports CSS3 selector supported by HTML::Selector::XPath.
Web::Query doesn't support jQuery's extended quries(yet?).

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF GMAIL COME<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
