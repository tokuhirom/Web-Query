package Web::Query;
our $AUTHORITY = 'cpan:TOKUHIROM';
# ABSTRACT: Yet another scraping library like jQuery
$Web::Query::VERSION = '0.34';
use strict;
use warnings;
use 5.008001;
use parent qw/Exporter/;
use HTML::TreeBuilder::XPath;
use LWP::UserAgent;
use HTML::Selector::XPath 0.06 qw/selector_to_xpath/;
use Scalar::Util qw/blessed refaddr/;
use HTML::Entities qw/encode_entities/;

use List::MoreUtils qw/ uniq /;
use Scalar::Util qw/ refaddr /;
our @EXPORT = qw/wq/;

our $RESPONSE;

sub wq { Web::Query->new(@_) }

our $UserAgent = LWP::UserAgent->new();

sub __ua {
    $UserAgent ||= LWP::UserAgent->new( agent => __PACKAGE__ . "/" . __PACKAGE__->VERSION );
    $UserAgent;
}

sub _build_tree {
    my( $self, $options ) = @_;

    my $no_space_compacting = ref $self ? $self->{no_space_compacting} 
    : ref $options eq 'HASH' ? $options->{no_space_compacting} : 0;

    my $tree = HTML::TreeBuilder::XPath->new( 
        no_space_compacting => $no_space_compacting
    );
    $tree->ignore_unknown(0);
    $tree->store_comments(1);
    $tree;
}

sub new {
    my ($class, $stuff, $options) = @_;

    my $self = $class->_resolve_new($stuff,$options)
        or return undef;

    $self->{indent} = $options->{indent} if $options->{indent};

    $self->{no_space_compacting} = $options->{no_space_compacting};

    return $self;
}

sub _resolve_new {
    my( $class, $stuff, $options) = @_;

    if (blessed $stuff) {
        return $class->new_from_element([$stuff],undef,$options)
            if $stuff->isa('HTML::Element');

        return $class->new_from_url($stuff->as_string,$options)
            if $stuff->isa('URI');

        return $class->new_from_element($stuff->{trees}, undef, $options)
            if $stuff->isa($class);

        die "Unknown source type: $stuff";
    }

    return $class->new_from_element($stuff,undef,$options) if ref $stuff eq 'ARRAY';

    return $class->new_from_url($stuff,$options) if $stuff =~ m{^(?:https?|file)://};

    return $class->new_from_html($stuff,$options) if $stuff =~ /<.*?>/;

    return $class->new_from_file($stuff,$options) if $stuff !~ /\n/ && -f $stuff;

    die "Unknown source type: $stuff";
}

sub new_from_url {
    my ($class, $url,$options) = @_;

    $RESPONSE = __ua()->get($url);

    return undef unless $RESPONSE->is_success;

    return $class->new_from_html($RESPONSE->decoded_content,$options);
}

sub new_from_file {
    my ($class, $fname, $options) = @_;
    my $tree = $class->_build_tree($options);
    $tree->parse_file($fname);
    my $self = $class->new_from_element([$tree->disembowel],undef,$options);
    $self->{need_delete}++;
    return $self;
}

sub new_from_html {
    my ($class, $html,$options) = @_;
    my $tree = $class->_build_tree($options);
    $tree->parse_content($html);
    my $self = $class->new_from_element([
            map {
                ref $_ ? $_ : bless { _content => $_ }, 'HTML::TreeBuilder::XPath::TextNode'
            } $tree->disembowel
    ],undef,$options);
    $self->{need_delete}++;
    return $self;
}

sub new_from_element {
    my $class = shift;
    my $trees = ref $_[0] eq 'ARRAY' ? $_[0] : [$_[0]];
    return bless { trees => [ @$trees ], before => $_[1] }, $class;
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

    my @new = map { $_->parent } @{$self->{trees}};

    return (ref $self || $self)->new_from_element(\@new, $self);
}

sub first {
    my $self = shift;
    return $self->eq(0);
}

sub last {
    my $self = shift;
    return $self->eq(-1);
}

sub get {
    my ($self, $index) = @_;
    return $self->{trees}[$index];
}

sub eq {
    my ($self, $index) = @_;
    return (ref $self || $self)->new_from_element([$self->{trees}[$index] || ()], $self);
}

sub find {
    my ($self, $selector) = @_;
    
    my $xpath = ref $selector ? $$selector : selector_to_xpath($selector, root => './');
    my @new = map { eval{ $_->findnodes($xpath) } } @{$self->{trees}};
    
    return (ref $self || $self)->new_from_element(\@new, $self);
}

sub contents {
    my ($self, $selector) = @_;

    my @new = map { $_->content_list } @{$self->{trees}};

    if ($selector) {
        my $xpath = ref $selector ? $$selector : selector_to_xpath($selector);
        @new = grep { $_->matches($xpath) } @new;
    }

    return (ref $self || $self)->new_from_element(\@new, $self);
}

sub as_html {
    my $self = shift;

    my @html = map {
        ref $_ ? ( $_->isa('HTML::TreeBuilder::XPath::TextNode') || $_->isa('HTML::TreeBuilder::XPath::CommentNode' ) )
                        ? $_->getValue 
                        : $_->as_HTML( q{&<>'"}, $self->{indent}, {} )
               : $_ 
    } @{$self->{trees}};

    return wantarray ? @html : $html[0];
}

sub html {
    my $self = shift;

    if (@_) {
        map {
            $_->delete_content;
            my $tree = $self->_build_tree;
            
            $tree->parse_content($_[0]);
            $_->push_content($tree->disembowel);
        } @{$self->{trees}};
        return $self;
    }

    my @html;
    for my $t ( @{$self->{trees}} ) {
        push @html, join '', map { 
            ref $_ ? $_->as_HTML( q{&<>'"}, $self->{indent}, {}) 
                   : encode_entities($_)
        } eval { $t->content_list };
    }
    
    return wantarray ? @html : $html[0];
}

sub text {
    my $self = shift;

    if (@_) {
        map { $_->delete_content; $_->push_content($_[0]) } @{$self->{trees}};
        return $self;
    }

    my @html = map { $_->as_text } @{$self->{trees}};
    return wantarray ? @html : $html[0];
}

sub attr {
    my $self = shift;

    if ( @_ == 1 ) { # getter 
        return wantarray 
            ? map { $_->attr(@_) } @{$self->{trees}}
            : eval { $self->{trees}[0]->attr(@_) }
            ;
    }

    $_->attr(@_) for @{$self->{trees}};

    return $self;
}

sub id {
    my $self = shift;

    if ( @_ ) {  # setter
        my $new_id = shift;

        return $self if $self->size == 0;

        return $self->each(sub{
            $_->attr( id => $new_id->(@_) )
        }) if ref $new_id eq 'CODE';

        if ( $self->size == 1 ) {
            $self->attr( id => $new_id );
        }
        else {
            return $self->first->attr( id => $new_id );
        }
    }
    else { # getter

        # the eval is there in case there is no tree
        return wantarray 
            ? map { $_->attr('id') } @{$self->{trees}}
            : eval { $self->{trees}[0]->attr('id') }
            ;
    }
}

sub name {
    my $self = shift;
    $self->attr( 'name', @_ );
}

sub data {
    my $self = shift;
    my $name = shift;
    $self->attr( join( '-', 'data', $name ), @_ );
}

sub tagname {
    my $self = shift;
    my @retval = map { $_ eq '~comment' ? '#comment' : $_ } 
                 map { ref $_ eq 'HTML::TreeBuilder::XPath::TextNode'    ? '#text' 
                     : ref $_ eq 'HTML::TreeBuilder::XPath::CommentNode' ? '#comment'
                     : ref $_ ? $_->tag(@_)
                     : '#text'
                     ;
                } @{$self->{trees}};
    return wantarray ? @retval : $retval[0];
}

sub each {
    my ($self, $code) = @_;
    my $i = 0;

    # make a copy such that if we modify the list via 'delete',
    # it won't change from under our feet (see t/each-and-delete.t 
    # for a case where it can)
    my @trees = @{ $self->{trees} };
    for my $tree ( @trees ) { 
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

    my @new;

    if (ref($_[0]) eq 'CODE') {
        my $code = $_[0];
        my $i = 0; 
        @new = grep {
            my $tree = $_;
            local $_ = (ref $self || $self)->new_from_element($tree);
            $code->($i++, $_);
        } @{$self->{trees}};
    }
    else {
        my $xpath = ref $_[0] ? ${$_[0]} : selector_to_xpath($_[0]);
        @new = grep { eval { $_->matches($xpath) } } @{$self->{trees}};        
    }

    return (ref $self || $self)->new_from_element(\@new, $self);
}

sub _is_same_node {
    refaddr($_[1]) == refaddr($_[2]);
}

sub remove {
    my $self = shift;
    my $before = $self->end;
    
    while (defined $before) {
        @{$before->{trees}} = grep {
            my $el = $_;            
            not grep { $self->_is_same_node( $el, $_ ) } @{$self->{trees}};            
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


            
        my $r = $rep->{trees}->[0];
        { no warnings;
            $r = $r->clone if ref $r;
        }
        $r->parent( $node->parent ) if ref $r and $node->parent;

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
        my $current_class = $t->attr('class') || '';
        
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

sub toggle_class {
    my $self = shift;
    
    my @classes = uniq @_;

    $self->each(sub{
        for my $class ( @classes ) {
            my $method = $_->has_class($class) ? 'remove_class' : 'add_class';
            $_->$method($class);
        }
    });
}

sub has_class {
    my ($self, $class) = @_;
    
    foreach my $t (@{$self->{trees}}) {
        no warnings 'uninitialized';
        return 1 if $t->attr('class') =~ /(?:^|\s)$class(?:\s|$)/;
    }
    
    return undef;   
}

sub clone {
    my ($self) = @_;
    my @clones = map { $_->clone } @{$self->{trees}};
    return (ref $self || $self)->new_from_element(\@clones);
}

sub add {
    my ($self, @stuff) = @_;
    my @nodes;
    
    # add(selector, context)
    if (@stuff == 2 && !ref $stuff[0] && $stuff[1]->isa('HTML::Element')) {
        my $xpath = ref $stuff[0] ? ${$stuff[0]} : selector_to_xpath($stuff[0]);
        push @nodes, $stuff[1]->findnodes( $xpath, root => './');
    }
    else {
        # handle any combination of html string, element object and web::query object
        push @nodes, map { 
            $self->{need_delete} = 1 if $_->{need_delete};
            delete $_->{need_delete};
            @{$_->{trees}}; 
        } map { (ref $self || $self)->new($_) } @stuff;                
    }

    my %ids = map { $self->_node_id($_) => 1 } @{ $self->{trees} };

    ( ref $self )->new_from_element( [ 
        @{$self->{trees}}, grep { ! $ids{ $self->_node_id($_) } } @nodes  
    ], $self );
}

sub _node_id {
    my( undef, $node ) = @_;
    refaddr $node;
}

sub prev {
    my $self = shift;
    my @new;
    for my $tree (@{$self->{trees}}) {
        push @new, $tree->getPreviousSibling;
    }
    return (ref $self || $self)->new_from_element(\@new, $self);
}

sub next {
    my $self = shift;

    my @new = grep { $_ } map { $_->getNextSibling } @{ $self->{trees} };

    return (ref $self || $self)->new_from_element(\@new, $self);
}

sub not {
    my( $self, $selector ) = @_;

    my $class = ref $self;

    my $xpath = ref $selector ? $$selector : selector_to_xpath($selector);
    $self->filter(sub { ! grep { $_->matches($xpath) } grep { ref $_ } $class->new($_)->{trees}[0] } );
}

sub and_back {
    my $self = shift;
    
    $self->add( $self->end );
}

sub next_until {
    my( $self, $selector ) = @_;

    my $class = ref $self;
    my $collection = $class->new_from_element([],$self);

    my $next = $self->next->not($selector);
    while( $next->size ) {
       $collection = $collection->add($next);
       $next = $next->next->not( $selector );
    }

    # hide the loop from the outside world
    $collection->{before} = $self;

    return $collection;
}

sub last_response {
    return $RESPONSE;
}

sub DESTROY {
    return unless $_[0]->{need_delete};

    # avoid memory leaks
    eval { $_->delete } for @{$_[0]->{trees}};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Web::Query - Yet another scraping library like jQuery

=head1 VERSION

version 0.34

=head1 SYNOPSIS

    use Web::Query;

    wq('http://www.w3.org/TR/html401/')
        ->find('div.head dt')
        ->each(sub {
            my $i = shift;
            printf("%d %s\n", $i+1, $_->text);
        });

=head1 DESCRIPTION

Web::Query is a yet another scraping framework, have a jQuery like interface.

Yes, I know Ingy's L<pQuery>. But it's just a alpha quality. It doesn't works.
Web::Query built at top of the CPAN modules, L<HTML::TreeBuilder::XPath>, L<LWP::UserAgent>, and L<HTML::Selector::XPath>.

So, this module uses L<HTML::Selector::XPath> and only supports the CSS 3
selector supported by that module.
Web::Query doesn't support jQuery's extended queries(yet?). If a selector is 
passed as a scalar ref, it'll be taken as a straight XPath expression.

    $wq( '<div><p>hello</p><p>there</p></div>' )->find( 'p' );       # css selector
    $wq( '<div><p>hello</p><p>there</p></div>' )->find( \'/div/p' ); # xpath selector

B<THIS LIBRARY IS UNDER DEVELOPMENT. ANY API MAY CHANGE WITHOUT NOTICE>.

=for stopwords prev

=head1 FUNCTIONS

=over 4

=item C<< wq($stuff) >>

This is a shortcut for C<< Web::Query->new($stuff) >>. This function is exported by default.

=back

=head1 METHODS

=head2 CONSTRUCTORS

=over 4

=item my $q = Web::Query->new($stuff, \%options )

Create new instance of Web::Query. You can make the instance from URL(http, https, file scheme), HTML in string, URL in string, L<URI> object, and instance of L<HTML::Element>.

This method throw the exception on unknown $stuff.

This method returns undefined value on non-successful response with URL.

Currently, the only two valid options are I<indent>, which will be used as
the indentation string if the object is printed, and I<no_space_compacting>, 
which will prevent the compaction of whitespace characters in text blocks.

=item my $q = Web::Query->new_from_element($element: HTML::Element)

Create new instance of Web::Query from instance of L<HTML::Element>.

=item C<< my $q = Web::Query->new_from_html($html: Str) >>

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

=back

=head2 TRAVERSING

=head3 add

Returns a new object augmented with the new element(s).

=over 4

=item add($html)

An HTML fragment to add to the set of matched elements.

=item add(@elements)

One or more @elements to add to the set of matched elements. 

@elements that already are part of the set are not added a second time.

    my $group = $wq->find('#foo');         # collection has 1 element
    $group = $group->add( '#bar', $wq );   # 2 elements
    $group->add( '#foo', $wq );            # still 2 elements

=item add($wq)

An existing Web::Query object to add to the set of matched elements.

=item add($selector, $context)

$selector is a string representing a selector expression to find additional elements to add to the set of matched elements.

$context is the point in the document at which the selector should begin matching

=back

=head3 contents

Get the immediate children of each element in the set of matched elements, including text and comment nodes.

=head3 each

Visit each nodes. C<< $i >> is a counter value, 0 origin. C<< $elem >> is iteration item.
C<< $_ >> is localized by C<< $elem >>.

    $q->each(sub { my ($i, $elem) = @_; ... })

=head3 end

Back to the before context like jQuery.

=head3 filter

Reduce the elements to those that pass the function's test.

    $q->filter(sub { my ($i, $elem) = @_; ... })

=head3 find

Get the descendants of each element in the current set of matched elements, filtered by a selector.

    my $q2 = $q->find($selector); # $selector is a CSS3 selector.

B<NOTE> If you want to match the element itself, use L</filter>.

B<INCOMPATIBLE CHANGE> 
From v0.14 to v0.19 (inclusive) find() also matched the element itself, which is not jQuery compatible.
You can achieve that result using C<filter()>, C<add()> and C<find()>:

    my $wq = wq('<div class="foo"><p class="foo">bar</p></div>'); # needed because we don't have a global document like jQuery does
    print $wq->filter('.foo')->add($wq->find('.foo'))->as_html; # <div class="foo"><p class="foo">bar</p></div><p class="foo">bar</p>

=head3 first

Return the first matching element.

This method constructs a new Web::Query object from the first matching element.

=head3 last

Return the last matching element.

This method constructs a new Web::Query object from the last matching element.

=head3 not($selector)

Return all the elements not matching the C<$selector>.

    # $do_for_love will be every thing, except #that
    my $do_for_love = $wq->find('thing')->not('#that');

=head3 and_back

Add the previous set of elements to the current one.

    # get the h1 plus everything until the next h1
    $wq->find('h1')->next_until('h1')->and_back;

=head3 map

Creates a new array with the results of calling a provided function on every element.

    $q->map(sub { my ($i, $elem) = @_; ... })

=head3 parent

Get the parent of each element in the current set of matched elements.

=head3 prev

Get the previous node of each element in the current set of matched elements.

    my $prev = $q->prev;

=head3 next

Get the next node of each element in the current set of matched elements.

   my $next = $q->next;

=head3 next_until( $selector )

Get all subsequent siblings, up to (but not including) the next node matched C<$selector>.

=head2 MANIPULATION

=head3 add_class

Adds the specified class(es) to each of the set of matched elements.

    # add class 'foo' to <p> elements
    wq('<div><p>foo</p><p>bar</p></div>')->find('p')->add_class('foo'); 

=head3 toggle_class( @classes )

Toggles the given class or classes on each of the element. I.e., if the element had the class, it'll be removed,
and if it hadn't, it'll be added.

Classes are toggled once, no matter how many times they appear in the argument list.

    $q->toggle_class( 'foo', 'foo', 'bar' );

    # equivalent to
    
    $q->toggle_class('foo')->toggle_class('bar');

    # and not

    $q->toggle_class('foo')->toggle_class('foo')->toggle_class('bar');

=head3 after

Insert content, specified by the parameter, after each element in the set of matched elements.

    wq('<div><p>foo</p></div>')->find('p')
                               ->after('<b>bar</b>')
                               ->end
                               ->as_html; # <div><p>foo</p><b>bar</b></div>

The content can be anything accepted by L</new>.

=head3 append

Insert content, specified by the parameter, to the end of each element in the set of matched elements.

    wq('<div></div>')->append('<p>foo</p>')->as_html; # <div><p>foo</p></div>

The content can be anything accepted by L</new>.

=head3 as_html

Return the elements associated with the object as strings. 
If called in a scalar context, only return the string representation
of the first element.

=head3 C< attr >

Get/set the attribute value in element.

In getter mode, it'll return either the values of the attribute
for all elements of the set, or only the first one depending of the calling context.

    my @values = $q->attr('style');      # style of all elements
    my $first_value = $q->attr('style'); # style of first element

In setter mode, it'll set the attribute value for all elements, and return back
the original object for easy chaining.

    $q->attr( 'alt' => 'a picture' )->find( ... );

=head3 C< id >

Get/set the elements's id attribute.

In getter mode, it behaves just like C<attr()>.

In setter mode, it behaves like C<attr()>, but with the following exceptions.

If the attribute value is a scalar, it'll be only assigned to
the first element of the set (as ids are supposed to be unique), and the returned object will only contain
that first element.

    my $first_element = $q->id('the_one');

It's possible to set the ids of all the elements by passing a sub to C<id()>. The sub is given the same arguments as for
C<each()>, and its return value is taken to be the new id of the elements.

    $q->id( sub { my $i = shift;  'foo_' . $i } );

=head3 C< name >

Get/set the elements's 'name' attribute.

    my $name = $q->name;  # equivalent to $q->attr( 'name' );

    $q->name( 'foo' );    # equivalent to $q->attr( name => 'foo' );

=head3 C< data >

Get/set the elements's 'data-*name*' attributes.

    my $data = $q->data('foo');  # equivalent to $q->attr( 'data-foo' );

    $q->data( 'foo' => 'bar' );  # equivalent to $q->attr( 'data-foo' => 'bar' );

=head3 tagname

Get/Set the tag name of elements.

    my $name = $q->tagname;

    $q->tagname($new_name);

=head3 before

Insert content, specified by the parameter, before each element in the set of matched elements.

    wq('<div><p>foo</p></div>')->find('p')
                               ->before('<b>bar</b>')
                               ->end
                               ->as_html; # <div><b>bar</b><p>foo</p></div>

The content can be anything accepted by L</new>.

=head3 clone

Create a deep copy of the set of matched elements.

=head3 detach

Remove the set of matched elements from the DOM.

=head3 has_class

Determine whether any of the matched elements are assigned the given class.

=head3 C< html >

Get/Set the innerHTML.

    my @html = $q->html();

    my $html = $q->html(); # 1st matching element only

    $q->html('<p>foo</p>');

=head3 insert_before

Insert every element in the set of matched elements before the target.

=head3 insert_after

Insert every element in the set of matched elements after the target.

=head3 C< prepend >

Insert content, specified by the parameter, to the beginning of each element in the set of matched elements. 

=head3 remove

Delete the elements associated with the object from the DOM.

    # remove all <blink> tags from the document
    $q->find('blink')->remove;

=head3 remove_class

Remove a single class, multiple classes, or all classes from each element in the set of matched elements.

=head3 replace_with

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

=head3 size

Return the number of elements in the Web::Query object.

    wq('<div><p>foo</p><p>bar</p></div>')->find('p')->size; # 2

=head3 text

Get/Set the text.

    my @text = $q->text();

    my $text = $q->text(); # 1st matching element only

    $q->text('text');

If called in a scalar context, only return the string representation
of the first element

=head2 OTHERS

=over 4

=item Web::Query->last_response()

Returns last HTTP response status that generated by C<new_from_url()>.

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

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/tokuhirom/Web-Query/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
