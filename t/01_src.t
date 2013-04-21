use strict;
use warnings;
use utf8;
use Test::More;
use Web::Query;
use Cwd ();

subtest 'from file' => sub {
    plan tests => 5;
    test(wq('t/data/foo.html'));
};

subtest 'from url' => sub {
    plan tests => 5;
    test(wq('file://' . Cwd::abs_path('t/data/foo.html')));
};

subtest 'from treebuilder' => sub {
    plan tests => 5;
    my $tree = HTML::TreeBuilder::XPath->new_from_file('t/data/foo.html');
    test(wq($tree));
};

subtest 'from Array[treebuilder]' => sub {
    plan tests => 5;
    my $tree = HTML::TreeBuilder::XPath->new_from_file('t/data/foo.html');
    test(wq([$tree]));
};

subtest 'from html' => sub {
    plan tests => 5;
    open my $fh, '<', 't/data/foo.html';
    my $html = do { local $/; <$fh> };
    test(wq($html));
};

if (eval "require URI; 1;") {
    subtest 'from URI' => sub {
        plan tests => 5;
        test(wq(URI->new('file://' . Cwd::abs_path('t/data/foo.html'))));
    };
}

my $wq = wq('file://' . Cwd::abs_path('t/data/html5_snippet.html'));
is scalar(grep { not ref $_ } @{$wq->{trees}}), 0, 'new_from_element skips non blessed';

done_testing;

sub test {
    $_[0]->find('.foo')->find('a')->each(sub {
             is $_->text, 'foo!';
             is $_->attr('href'), '/foo';
         })
         ->end()->end()
         ->find('.bar')->find('a')->each(sub {
             is $_->text, 'bar!';
             is $_->attr('href'), '/bar';
             $_->attr('href' => '/bar2');
             note $_->html;
         });
    like $_[0]->html, qr{href="/bar2"};
}

