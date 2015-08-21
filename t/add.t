#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Web::Query;

test('Web::Query');
test('Web::Query::LibXML') if eval "require Web::Query::LibXML; 1";

done_testing;

    
sub test {
    my $class = shift;    
    diag "testing $class";
    no warnings 'redefine';
    *wq = \&{$class . "::wq" };
    
    my $html = <<HTML;
    <div class="container">
      <div class="foo">Foo</div>
      <div class="bar">Bar</div>
    </div>
HTML
    
    
    # add($object)
    is join('|', wq($html)->find('.foo')->add(wq($html)->find('.bar'))->as_html)
        => '<div class="foo">Foo</div>|<div class="bar">Bar</div>', 'add($object)';
    
    
    # add($html)
    is join('|', wq($html)->find('.foo')->add('<div class="bar">Bar</div>')->as_html)
        => '<div class="foo">Foo</div>|<div class="bar">Bar</div>', 'add($html)';
    
    # add(@elements)
    is join('|', wq($html)->find('.foo')->add(@{ wq($html)->find('div')->{trees}})->as_html)
        => '<div class="foo">Foo</div>|<div class="foo">Foo</div>|<div class="bar">Bar</div>', 'add(@elements)';
    
    # add($selector, $xpath_context)
    is join('|', wq($html)->find('.foo')->add('.bar', wq($html)->{trees}->[0] )->as_html)
        => '<div class="foo">Foo</div>|<div class="bar">Bar</div>', 'add($selector, $xpath_context)';

    subtest  "add() create new object" => sub {
        my $wq = wq($html);
        my $x = $wq->find('.foo');
        my $y = $x->add( $wq->find('.bar') );

        is $x->size => 1, "original object";
        is $y->size => 2, "new object";
    };

    subtest "add() doesn't add the same node twice" => sub {
        my $wq = wq($html);
        my $x = $wq->find('.foo')->add( $wq->find('.foo') );
        is $x->size => 1, "only one node";
    };
}
