package Web::Query;
use strict;
use warnings;
use 5.008001;
use parent qw/Exporter/;
our $VERSION = '0.06';
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;
use HTML::Selector::XPath 0.06 qw/selector_to_xpath/;
use Scalar::Util qw/blessed/;
use HTML::Entities qw/encode_entities/;

our @EXPORT = qw/wq/;

sub wq { Web::Query->new(@_) }

our $UserAgent = LWP::UserAgent->new();

sub __ua {
    $UserAgent ||= LWP::UserAgent->new( agent => __PACKAGE__ . "/" . $VERSION );
    $UserAgent;
}

sub new {
    my ($class, $stuff) = @_;
    if (blessed $stuff) {
        if ($stuff->isa('HTML::Element')) {
            return $class->new_from_element([$stuff]);
        } elsif ($stuff->isa('URI')) {
            return $class->new_from_url($stuff->as_string);
        } else {
            die "Unknown source type: $stuff";
        }
    } elsif (ref $stuff eq 'ARRAY') {
        return $class->new_from_element($stuff);
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
    $tree->ignore_unknown(0);
    my $self = $class->new_from_element([$tree->elementify]);
    $self->{need_delete}++;
    return $self;
}

sub new_from_html {
    my ($class, $html) = @_;
    my $tree = HTML::TreeBuilder::XPath->new();
    $tree->ignore_unknown(0);
    $tree->parse_content($html);
    my $self = $class->new_from_element([$tree->elementify]);
    $self->{need_delete}++;
    return $self;
}

sub new_from_element {
    my $class = shift;
    my $trees = ref $_[0] eq 'ARRAY' ? $_[0] : +[$_[0]];
    return bless { trees => $trees, before => $_[1] }, $class;
}

sub end {
    my $self = shift;
    return $self->{before};
}

sub size {
    my $self = shift;
    return scalar(@{$self->{trees}});
}

sub parent {
    my $self = shift;
    my @new;
    for my $tree (@{$self->{trees}}) {
        push @new, $tree->getParentNode();
    }
    return Web::Query->new_from_element(\@new, $self);
}

sub first {
    my $self = shift;
    $self->{trees} = +[$self->{trees}[0]];
    return $self;
}

sub last {
    my $self = shift;
    $self->{trees} = +[$self->{trees}[-1]];
    return $self;
}

sub find {
    my ($self, $selector) = @_;
    my @new;
    for my $tree (@{$self->{trees}}) {
        $selector = selector_to_xpath($selector, root => './');
        push @new, $tree->findnodes($selector);
    }
    return Web::Query->new_from_element(\@new, $self);
}

sub html {
    my $self = shift;

    if (@_) {
        map { $_->delete_content; $_->push_content(HTML::TreeBuilder->new_from_content($_[0])->guts) } @{$self->{trees}};
        return $self;
    } else {
        my @html = map { $_->as_HTML(q{&<>'"}) } @{$self->{trees}};
        return wantarray ? @html : $html[0];
    }
}

sub text {
    my $self = shift;
    if (@_) {
        map { $_->delete_content; $_->push_content($_[0]) } @{$self->{trees}};
        return $self;
    } else {
        my @html = map { $_->as_text } @{$self->{trees}};
        return wantarray ? @html : $html[0];
    }
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
                printf("%d) %s\n", $i+1, $_->text
          });

=head1 DESCRIPTION

Web::Query is a yet another scraping framework, have a jQuery like interaface.

Yes, I know ingy's pQuery. But it's just a alpha quality. It doesn't works.
Web::Query built at top of the CPAN modules, L<HTML::TreeBuilder::XPath>, L<LWP::UserAgent>, and L<HTML::Selector::XPath>.

So, this module uses L<HTML::Selector::XPath>, then this module only supports CSS3 selector supported by HTML::Selector::XPath.
Web::Query doesn't support jQuery's extended quries(yet?).

B<THIS LIBRARY IS UNDER DEVELOPMENT. ANY API MAY CHANGE WITHOUT NOTICE>.

=head1 FUNCTIONS

=over 4

=item wq($stuff)

This is a shortcut for C<< Web::Query->new($stuff) >>. This function is exported by default.

=back

=head1 METHODS

=over 4

=item my $q = Web::Query->new($stuff)

Create new instance of Web::Query. You can make the instance from URL(http, https, file scheme), HTML in string, URL in string, L<URI> object, and instance of L<HTML::Element>.

=item my $q = Web::Query->new_from_element($element: HTML::Element)

Create new instance of Web::Query from instance of L<HTML::Element>.

=item my $q = Web::Query->new_from_html($html: Str)

Create new instance of Web::Query from html.

=item my $q = Web::Query->new_from_url($url: Str)

Create new instance of Web::Query from url.

=item my $q = Web::Query->new_from_file($file_name: Str)

Create new instance of Web::Query from file name.

=item my @html = $q->html();

=item my $html = $q->html();

=item $q->html('<p>foo</p>');

Get/set the innerHTML.

=item my @text = $q->text();

=item my $text = $q->text();

=item $q->text('text');

Get/Set the inner text.

=item my $attr = $q->attr($name);

=item $q->attr($name, $val);

Get/Set the attribute value in element.

=item $q = $q->find($selector)

This method find nodes by $selector from $q. $selector is a CSS3 selector.

=item $q->each(sub { my ($i, $elem) = @_; ... })

Visit each nodes. C<< $i >> is a counter value, 0 origin. C<< $elem >> is iteration item.
C<< $_ >> is localized by C<< $elem >>.

=item $q->end()

Back to the before context like jQuery.

=item my $size = $q->size() : Int

Return the number of DOM elements matched by the Web::Query object.

=item my $parent = $q->parent() : Web::Query

Return the parent node from C<< $q >>.

=item my $first = $q->first()

Return the first matching element.

=item my $last = $q->last()

Return the last matching element.

=back

=head1 HOW DO I CUSTOMIZE USER AGENT?

You can specify your own instance of L<LWP::UserAgent>.

    $Web::Query::UserAgent = LWP::UserAgent->new( agent => 'Mozilla/5.0' );

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<pQuery>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
