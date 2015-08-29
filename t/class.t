#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';

use WQTest;

WQTest::test {
    my $class = shift;

    subtest 'toggle_class' => sub { test_toggle_class($class) };

    subtest 'add_class' => sub { test_add_class($class) };

};

sub test_toggle_class {
    my $class = shift;    

    my $q = $class->new(q{
        <div>
            <a class="foo bar"/>
            <a />
            <a class="foo" />
        </div>
    })->find('a');

    $q->toggle_class( 'foo' );

    is_deeply $q->map( sub { $_->has_class('foo') } ), [ undef, 1, undef ];

    $q->toggle_class( 'foo', 'bar' );
    is_deeply $q->map( sub { $_->has_class('foo') } ), [ 1, undef, 1 ];
    is_deeply $q->map( sub { $_->has_class('bar') } ), [ undef, 1, 1 ];

    subtest "double toggling" => sub {
        $q->toggle_class( 'foo', 'foo' );
        is_deeply $q->map( sub { $_->has_class('foo') } ), [ undef, 1, undef ];
    };
}

sub test_add_class {
    my $class = shift;    
    
    my $html = '<div class="container"><div class="inner">Hello</div><div class="inner">Goodbye</div></div>';
    
    my $wq = $class->new($html);
    
    $wq->find('.inner')->add_class('foo bar inner');    
    is $wq->as_html, '<div class="container"><div class="inner foo bar">Hello</div><div class="inner foo bar">Goodbye</div></div>', 'add_class("foo bar inner")';
    
    # add_class(CODE)
    $wq = $class->new($html);
    
    $wq->find('.inner')->add_class(sub{
        my ($i, $current, $el) = @_;
        return "foo-$i bar";
    });
    
    is $wq->as_html, '<div class="container"><div class="inner foo-0 bar">Hello</div><div class="inner foo-1 bar">Goodbye</div></div>', 'add_class(CODE)';

}
