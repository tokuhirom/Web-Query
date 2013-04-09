package Web::Query;
use strict;
use warnings;
use 5.008001;
use parent qw/Exporter/;
our $VERSION = '0.15';
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;
use HTML::Selector::XPath 0.06 qw/selector_to_xpath/;
use Scalar::Util qw/blessed refaddr/;
use HTML::Entities qw/encode_entities/;

our @EXPORT = qw/wq/;

our $RESPONSE;

sub wq { Web::Query->new(@_) }

our $UserAgent = LWP::UserAgent->new();

sub __ua {
    $UserAgent ||= LWP::UserAgent->new( agent => __PACKAGE__ . "/" . $VERSION );
    $UserAgent;
}

sub new {
    my ($class, $stuff, $options) = @_;

    my $self = $class->_resolve_new($stuff);

    $self->{indent} = $options->{indent} if $options->{indent};

    return $self;
}

sub _resolve_new {
    my( $class, $stuff ) = @_;

    if (blessed $stuff) {
        if ($stuff->isa('HTML::Element')) {
            return $class->new_from_element([$stuff]);
        } 
        
        if ($stuff->isa('URI')) {
            return $class->new_from_url($stuff->as_string);
        } 

        die "Unknown source type: $stuff";
    }

    return $class->new_from_element($stuff) if ref $stuff eq 'ARRAY';

    return $class->new_from_url($stuff) if $stuff =~ m{^(?:https?|file)://};

    return $class->new_from_html($stuff) if $stuff =~ /<.*?>/;

    return $class->new_from_file($stuff) if $stuff !~ /\n/ && -f $stuff;

    die "Unknown source type: $stuff";
}

sub new_from_url {
    my ($class, $url) = @_;
    $RESPONSE = __ua()->get($url);
    if ($RESPONSE->is_success) {
        return $class->new_from_html($RESPONSE->decoded_content);
    } else {
        return undef;
    }
}

sub new_from_file {
    my ($class, $fname) = @_;
    my $tree = HTML::TreeBuilder::XPath->new_from_file($fname);
    $tree->ignore_unknown(0);
    $tree->store_comments(1);
    my $self = $class->new_from_element([$tree->elementify]);
    $self->{need_delete}++;
    return $self;
}

sub new_from_html {
    my ($class, $html) = @_;
    my $tree = HTML::TreeBuilder::XPath->new();
    $tree->ignore_unknown(0);
    $tree->store_comments(1);
    $tree->parse_content($html);
    my $self = $class->new_from_element([$tree->guts]);
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
    return (ref $self || $self)->new_from_element(\@new, $self);
}

sub first {
    my $self = shift;
    return (ref $self || $self)->new_from_element([$self->{trees}[0] || ()], $self);
}

sub last {
    my $self = shift;
    return (ref $self || $self)->new_from_element([$self->{trees}[-1] || ()], $self);
}

sub find {
    my ($self, $selector) = @_;
    my $xpath_rootless = selector_to_xpath($selector);
    
    my @new;
    for my $tree (@{$self->{trees}}) {
        push @new, $tree if defined $tree->parent && $tree->matches($xpath_rootless);
        push @new, $tree->findnodes(selector_to_xpath($selector, root => defined $tree->parent ? './' : '/'));
    }
    
    return (ref $self || $self)->new_from_element(\@new, $self);
}

sub as_html {
    my $self = shift;

    my @html = map { $_->as_HTML( q{&<>'"}, $self->{indent}, {} ) }
        @{$self->{trees}};

    return wantarray ? @html : $html[0];
}

sub html {
    my $self = shift;
    my $builder = HTML::TreeBuilder->new;
    $builder->store_comments(1);
    
    if (@_) {
        map { 
            $_->delete_content; 
            my $tree = HTML::TreeBuilder->new;
            $tree->ignore_unknown(0);
            $tree->store_comments(1);
            $tree->parse_content($_[0]);
            $_->push_content($tree->guts);
        } @{$self->{trees}};
        return $self;
    } 

    my @html;
    for my $t ( @{$self->{trees}} ) {
        push @html, join '', map { 
            ref $_ ? $_->as_HTML( q{&<>'"}, $self->{indent}, {}) 
                   : encode_entities($_)
        } $t->content_list;
    }
    
    return wantarray ? @html : $html[0];
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
        local $_ = (ref $self || $self)->new_from_element([$tree], $self);
        $code->($i++, $_);
    }
    return $self;
}

sub map {
    my ($self, $code) = @_;
    my $i = 0; 
    return +[map {
        my $tree = $_;
        local $_ = (ref $self || $self)->new($tree);
        $code->($i++, $_);
    } @{$self->{trees}}];
}   

sub filter {
    my $self = shift;

    if (ref($_[0]) eq 'CODE') {
        my $code = $_[0];
        my $i = 0; 
        $self->{trees} = +[grep {
            my $tree = $_;
            local $_ = (ref $self || $self)->new($tree);
            $code->($i++, $_);
        } @{$self->{trees}}];
        return $self;

    } else {
        return $self->find($_[0])
    }
}

sub remove {
    my $self = shift;
    my $before = $self->end;
    
    while (defined $before) {
        @{$before->{trees}} = grep {
            my $el = $_;            
            not grep { refaddr($el) == refaddr($_) } @{$self->{trees}};            
        } @{$before->{trees}};

        $before = $before->end;
    }
    
    $_->delete for @{$self->{trees}};
    @{$self->{trees}} = ();
    
    $self;
}

sub replace_with {
    my ( $self, $replacement ) = @_;

    my $i = 0;
    for my $node ( @{ $self->{trees} } ) {
        my $rep = $replacement;

        if ( ref $rep eq 'CODE' ) {
            local $_ = (ref $self || $self)->new($node);
            $rep = $rep->( $i++ => $_ ); 
        }

        $rep = (ref $self || $self)->new_from_html( $rep )
            unless ref $rep;

        my $r = $rep->{trees}->[0]->clone;
        $r->parent( $node->parent ) if $node->parent;

        $node->replace_with( $r );
    }

    $replacement->remove if ref $replacement eq (ref $self || $self);

    return $self;
}

sub append {
    my ($self, $stuff) = @_;
    $stuff = (ref $self || $self)->new($stuff);
    
    foreach my $t (@{$self->{trees}}) {
        $t->push_content($_) for ref($t)->clone_list(@{$stuff->{trees}});
    }
    
    $self;    
}

sub prepend {
    my ($self, $stuff) = @_;
    $stuff = (ref $self || $self)->new($stuff);
    
    foreach my $t (@{$self->{trees}}) {
        $t->unshift_content($_) for ref($t)->clone_list(@{$stuff->{trees}});
    }
    
    $self;    
}


sub before {
    my ($self, $stuff) = @_;
    $stuff = (ref $self || $self)->new($stuff);
        
    foreach my $t (@{$self->{trees}}) {
        $t->preinsert(ref($t)->clone_list(@{$stuff->{trees}}));
    }
    
    $self;    
}


sub after {
    my ($self, $stuff) = @_;
    $stuff = (ref $self || $self)->new($stuff);
        
    foreach my $t (@{$self->{trees}}) {
        $t->postinsert(ref($t)->clone_list(@{$stuff->{trees}}));
    }
    
    $self;    
}


sub insert_before {
    my ($self, $target) = @_;
        
    foreach my $t (@{$target->{trees}}) {
        $t->preinsert(ref($t)->clone_list(@{$self->{trees}}));
    }
    
    $self;    
}

sub insert_after {
    my ($self, $target) = @_;
        
    foreach my $t (@{$target->{trees}}) {
        $t->postinsert(ref($t)->clone_list(@{$self->{trees}}));
    }
    
    $self;    
}

sub detach {
    my ($self) = @_;
    $_->detach for @{$self->{trees}};
    $self;    
}

sub add_class {
    my ($self, $class) = @_;    
            
    for (my $i = 0; $i < @{$self->{trees}}; $i++) {
        my $t = $self->{trees}->[$i];        
        my $current_class = $t->attr('class');
        
        my $classes = ref $class eq 'CODE' ? $class->($i, $current_class, $t) : $class;
        my @classes = split /\s+/, $classes;
        
        foreach (@classes) {            
            $current_class .= " $_" unless $current_class =~ /(?:^|\s)$_(?:\s|$)/;     
        }
                        
        $current_class =~ s/(?:^\s*|\s*$)//g;
        $current_class =~ s/\s\s+/ /g;
        
        $t->attr('class', $current_class);
    }
    
    $self;    
}


sub remove_class {
    my ($self, $class) = @_;

    for (my $i = 0; $i < @{$self->{trees}}; $i++) {
        my $t = $self->{trees}->[$i];        
        my $current_class = $t->attr('class');
        next unless defined $current_class;        
        
        my $classes = ref $class eq 'CODE' ? $class->($i, $current_class, $t) : $class;
        my @remove_classes = split /\s+/, $classes;
        my @final = grep {
            my $existing_class = $_;     
            not grep { $existing_class eq $_} @remove_classes;
        } split /\s+/, $current_class;
        
        $t->attr('class', join ' ', @final);
    }
    
    $self; 
    
}


sub has_class {
    my ($self, $class) = @_;
    
    foreach my $t (@{$self->{trees}}) {
        return 1 if $t->attr('class') =~ /(?:^|\s)$class(?:\s|$)/;
    }
    
    return;   
}

sub clone {
    my ($self) = @_;
    my @clones = map { $_->clone } @{$self->{trees}};
    return (ref $self || $self)->new_from_element(\@clones);
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

Web::Query is a yet another scraping framework, have a jQuery like interface.

Yes, I know ingy's L<pQuery>. But it's just a alpha quality. It doesn't works.
Web::Query built at top of the CPAN modules, L<HTML::TreeBuilder::XPath>, L<LWP::UserAgent>, and L<HTML::Selector::XPath>.

So, this module uses L<HTML::Selector::XPath> and only supports the CSS 3
selector supported by that module.
Web::Query doesn't support jQuery's extended queries(yet?).

B<THIS LIBRARY IS UNDER DEVELOPMENT. ANY API MAY CHANGE WITHOUT NOTICE>.

=head1 FUNCTIONS

=over 4

=item wq($stuff)

This is a shortcut for C<< Web::Query->new($stuff) >>. This function is exported by default.

=back

=head1 METHODS

=over 4

=item my $q = Web::Query->new($stuff, \%options )

Create new instance of Web::Query. You can make the instance from URL(http, https, file scheme), HTML in string, URL in string, L<URI> object, and instance of L<HTML::Element>.

This method throw the exception on unknown $stuff.

This method returns undefined value on non-successful response with URL.

Currently, the only option valid option is I<indent>, which will be used as
the indentation string if the object is printed.

=item my $q = Web::Query->new_from_element($element: HTML::Element)

Create new instance of Web::Query from instance of L<HTML::Element>.

=item my $q = Web::Query->new_from_html($html: Str)

Create new instance of Web::Query from HTML.

=item my $q = Web::Query->new_from_url($url: Str)

Create new instance of Web::Query from URL.

If the response is not success(It means /^20[0-9]$/), this method returns undefined value.

You can get a last result of response, use the C<< $Web::Query::RESPONSE >>.

Here is a best practical code:

    my $url = 'http://example.com/';
    my $q = Web::Query->new_from_url($url)
        or die "Cannot get a resource from $url: " . Web::Query->last_response()->status_line;

=item my $q = Web::Query->new_from_file($file_name: Str)

Create new instance of Web::Query from file name.

=item my @html = $q->html();

=item my $html = $q->html();

=item $q->html('<p>foo</p>');

Get/Set the innerHTML.

=item $q->as_html();

Return the elements associated with the object as strings. 
If called in a scalar context, only return the string representation
of the first element.

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

=item $q->map(sub { my ($i, $elem) = @_; ... })

Creates a new array with the results of calling a provided function on every element.

=item $q->filter(sub { my ($i, $elem) = @_; ... })

Reduce the elements to those that pass the function's test.

=item $q->end()

Back to the before context like jQuery.

=item my $size = $q->size() : Int

Return the number of DOM elements matched by the Web::Query object.

=item my $parent = $q->parent() : Web::Query

Return the parent node from C<< $q >>.

=item my $first = $q->first()

Return the first matching element.

This method constructs a new Web::Query object from the first matching element.

=item my $last = $q->last()

Return the last matching element.

This method constructs a new Web::Query object from the last matching element.

=item $q->remove()

Delete the elements associated with the object from the DOM.

    # remove all <blink> tags from the document
    $q->find('blink')->remove;

=item $q->replace_with( $replacement );

Replace the elements of the object with the provided replacement. 
The replacement can be a string, a C<Web::Query> object or an 
anonymous function. The anonymous function is passed the index of the current 
node and the node itself (with is also localized as C<$_>).

    my $q = wq( '<p><b>Abra</b><i>cada</i><u>bra</u></p>' );

    $q->find('b')->replace_with('<a>Ocus</a>);
        # <p><a>Ocus</a><i>cada</i><u>bra</u></p>

    $q->find('u')->replace_with($q->find('b'));
        # <p><i>cada</i><b>Abra</b></p>

    $q->find('i')->replace_with(sub{ 
        my $name = $_->text;
        return "<$name></$name>";
    });
        # <p><b>Abra</b><cada></cada><u>bra</u></p>

=back

=head1 HOW DO I CUSTOMIZE USER AGENT?

You can specify your own instance of L<LWP::UserAgent>.

    $Web::Query::UserAgent = LWP::UserAgent->new( agent => 'Mozilla/5.0' );

=head1 INCOMPATIBLE CHANGES

=over 4

=item 0.10

new_from_url() is no longer throws exception on bad response from HTTP server.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 SEE ALSO

L<pQuery>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
