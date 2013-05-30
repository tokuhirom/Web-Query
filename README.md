# NAME

Web::Query - Yet another scraping library like jQuery

# SYNOPSIS

    use Web::Query;

    wq('http://google.com/search?q=foobar')
          ->find('h2')
          ->each(sub {
                my $i = shift;
                printf("%d) %s\n", $i+1, $_->text
          });

# DESCRIPTION

Web::Query is a yet another scraping framework, have a jQuery like interface.

Yes, I know Ingy's [pQuery](http://search.cpan.org/perldoc?pQuery). But it's just a alpha quality. It doesn't works.
Web::Query built at top of the CPAN modules, [HTML::TreeBuilder::XPath](http://search.cpan.org/perldoc?HTML::TreeBuilder::XPath), [LWP::UserAgent](http://search.cpan.org/perldoc?LWP::UserAgent), and [HTML::Selector::XPath](http://search.cpan.org/perldoc?HTML::Selector::XPath).

So, this module uses [HTML::Selector::XPath](http://search.cpan.org/perldoc?HTML::Selector::XPath) and only supports the CSS 3
selector supported by that module.
Web::Query doesn't support jQuery's extended queries(yet?).

__THIS LIBRARY IS UNDER DEVELOPMENT. ANY API MAY CHANGE WITHOUT NOTICE__.

# FUNCTIONS

- `wq($stuff)`

    This is a shortcut for `Web::Query->new($stuff)`. This function is exported by default.

# METHODS

## CONSTRUCTORS

- my $q = Web::Query->new($stuff, \\%options )

    Create new instance of Web::Query. You can make the instance from URL(http, https, file scheme), HTML in string, URL in string, [URI](http://search.cpan.org/perldoc?URI) object, and instance of [HTML::Element](http://search.cpan.org/perldoc?HTML::Element).

    This method throw the exception on unknown $stuff.

    This method returns undefined value on non-successful response with URL.

    Currently, the only option valid option is _indent_, which will be used as
    the indentation string if the object is printed.

- my $q = Web::Query->new\_from\_element($element: HTML::Element)

    Create new instance of Web::Query from instance of [HTML::Element](http://search.cpan.org/perldoc?HTML::Element).

- my $q = Web::Query->new\_from\_html($html: Str)

    Create new instance of Web::Query from HTML.

- my $q = Web::Query->new\_from\_url($url: Str)

    Create new instance of Web::Query from URL.

    If the response is not success(It means /^20\[0-9\]$/), this method returns undefined value.

    You can get a last result of response, use the `$Web::Query::RESPONSE`.

    Here is a best practical code:

        my $url = 'http://example.com/';
        my $q = Web::Query->new_from_url($url)
            or die "Cannot get a resource from $url: " . Web::Query->last_response()->status_line;

- my $q = Web::Query->new\_from\_file($file\_name: Str)

    Create new instance of Web::Query from file name.

## TRAVERSING

### add

Add elements to the set of matched elements.

- add($html)

    An HTML fragment to add to the set of matched elements.

- add(@elements)

    One or more @elements to add to the set of matched elements.

- add($wq)

    An existing Web::Query object to add to the set of matched elements.

- add($selector, $context)

    $selector is a string representing a selector expression to find additional elements to add to the set of matched elements.

    $context is the point in the document at which the selector should begin matching

### contents

Get the immediate children of each element in the set of matched elements, including text and comment nodes.

### each

Visit each nodes. `$i` is a counter value, 0 origin. `$elem` is iteration item.
`$_` is localized by `$elem`.

    $q->each(sub { my ($i, $elem) = @_; ... })

### end

Back to the before context like jQuery.

### filter

Reduce the elements to those that pass the function's test.

    $q->filter(sub { my ($i, $elem) = @_; ... })

### find

Get the descendants of each element in the current set of matched elements, filtered by a selector.

    my $q2 = $q->find($selector); # $selector is a CSS3 selector.
    

__NOTE__ If you want to match the element itself, use ["filter"](#filter).

__INCOMPATIBLE CHANGE__ 
From v0.14 to v0.19 (inclusive) find() also matched the element itself, which is not jQuery compatible.
You can achieve that result using `filter()`, `add()` and `find()`:

    my $wq = wq('<div class="foo"><p class="foo">bar</p></div>'); # needed because we don't have a global document like jQuery does
    print $wq->filter('.foo')->add($wq->find('.foo'))->as_html; # <div class="foo"><p class="foo">bar</p></div><p class="foo">bar</p>

### first

Return the first matching element.

This method constructs a new Web::Query object from the first matching element.

### last

Return the last matching element.

This method constructs a new Web::Query object from the last matching element.

### map

Creates a new array with the results of calling a provided function on every element.

    $q->map(sub { my ($i, $elem) = @_; ... })

### parent

Get the parent of each element in the current set of matched elements.

## MANIPULATION

### add\_class

Adds the specified class(es) to each of the set of matched elements.

    # add class 'foo' to <p> elements
    wq('<div><p>foo</p><p>bar</p></div>')->find('p')->add_class('foo'); 

### after

Insert content, specified by the parameter, after each element in the set of matched elements.

    wq('<div><p>foo</p></div>')->find('p')
                               ->after('<b>bar</b>')
                               ->end
                               ->as_html; # <div><p>foo</p><b>bar</b></div>
    

The content can be anything accepted by ["new"](#new).

### append

Insert content, specified by the parameter, to the end of each element in the set of matched elements.

    wq('<div></div>')->append('<p>foo</p>')->as_html; # <div><p>foo</p></div>
    

The content can be anything accepted by ["new"](#new).

### as\_html

Return the elements associated with the object as strings. 
If called in a scalar context, only return the string representation
of the first element.

### attr

Get/Set the attribute value in element.

    my $attr = $q->attr($name);

    $q->attr($name, $val);

### before

Insert content, specified by the parameter, before each element in the set of matched elements.

    wq('<div><p>foo</p></div>')->find('p')
                               ->before('<b>bar</b>')
                               ->end
                               ->as_html; # <div><b>bar</b><p>foo</p></div>
    

The content can be anything accepted by ["new"](#new).

### clone

Create a deep copy of the set of matched elements.

### detach

Remove the set of matched elements from the DOM.

### has\_class

Determine whether any of the matched elements are assigned the given class.

### html

Get/Set the innerHTML.

    my @html = $q->html();

    my $html = $q->html(); # 1st matching element only

    $q->html('<p>foo</p>');

### insert\_before

Insert every element in the set of matched elements before the target.

### insert\_after

Insert every element in the set of matched elements after the target.

### prepend

Insert content, specified by the parameter, to the beginning of each element in the set of matched elements. 

### remove

Delete the elements associated with the object from the DOM.

    # remove all <blink> tags from the document
    $q->find('blink')->remove;

### remove\_class

Remove a single class, multiple classes, or all classes from each element in the set of matched elements.

### replace\_with

Replace the elements of the object with the provided replacement. 
The replacement can be a string, a `Web::Query` object or an 
anonymous function. The anonymous function is passed the index of the current 
node and the node itself (with is also localized as `$_`).

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

### size

Return the number of elements in the Web::Query object.

    wq('<div><p>foo</p><p>bar</p></div>')->find('p')->size; # 2

### text

Get/Set the text.

    my @text = $q->text();

    my $text = $q->text(); # 1st matching element only

    $q->text('text');
    

If called in a scalar context, only return the string representation
of the first element

# HOW DO I CUSTOMIZE USER AGENT?

You can specify your own instance of [LWP::UserAgent](http://search.cpan.org/perldoc?LWP::UserAgent).

    $Web::Query::UserAgent = LWP::UserAgent->new( agent => 'Mozilla/5.0' );

# INCOMPATIBLE CHANGES

0. 10

    new\_from\_url() is no longer throws exception on bad response from HTTP server.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

[pQuery](http://search.cpan.org/perldoc?pQuery)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
