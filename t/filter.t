use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't/lib';

use WQTest;

WQTest::test {
    my $class = shift;
    
    my $html = <<HTML;
    <div class="container">
      <div class="inner">Hello</div>
    </div>
    
    <div>
      <div class="inner">Hello</div>
    </div>
HTML

    my $q = $class->new($html);

    subtest "selector" => sub {
        is $q->filter('span')->size, 0;
        is $q->filter('div.container')->size, 1;
        is $q->filter('div')->size, 2;
    };

    subtest coderef => sub {
        is $q->size, 2;

        is $q->filter(sub { $_->has_class( 'container' ) } )->size, 1;
        
        # 'filter' on a coderef was modifying the parent element
        is $q->size, 2, 'still two elements';
    };

    subtest on_text => sub { on_text($class) };
};

sub on_text {
    my $class = shift;

    my $wq = $class->new('<div class="foo"><p class="foo">bar</p></div>Standalone Text');

    lives_ok { $wq->filter('.foo') }, "doesn't explode on text nodes";
}
