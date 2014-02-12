use strict;
use warnings;
use utf8;
use Test::More;
use Cwd ();
use Web::Query;

test('Web::Query');
test('Web::Query::LibXML') if eval "require Web::Query::LibXML; 1";

done_testing;


sub test {
    my $class = shift;    
    diag "testing $class";
    no warnings 'redefine';
    *wq = \&{$class . "::wq" };
    
    subtest 'from file' => sub {
        plan tests => 5;
        run_tests(wq('t/data/foo.html'));
    };
    
    is wq('t/data/html5_snippet.html')->size, 3, 'snippet from file';
    
    subtest 'from url' => sub {
        plan tests => 5;
        run_tests(wq('file://' . Cwd::abs_path('t/data/foo.html')));
    };
    
    subtest 'from treebuilder' => sub {
        plan tests => 5;
        my $tree = HTML::TreeBuilder::XPath->new_from_file('t/data/foo.html');
        run_tests(wq($tree));
    };
    
    subtest 'from Array[treebuilder]' => sub {
        plan tests => 5;
        my $tree = HTML::TreeBuilder::XPath->new_from_file('t/data/foo.html');
        run_tests(wq([$tree]));
    };
    
    subtest 'from html' => sub {
        plan tests => 5;
        open my $fh, '<', 't/data/foo.html';
        my $html = do { local $/; <$fh> };
        run_tests(wq($html));
    };
    
    subtest 'from Web::Query object' => sub {
        plan tests => 5;
        my $tree = HTML::TreeBuilder::XPath->new_from_file('t/data/foo.html');
        run_tests(wq(wq($tree)));
    };
    
    if (eval "require URI; 1;") {
        subtest 'from URI' => sub {
            plan tests => 5;
            run_tests(wq(URI->new('file://' . Cwd::abs_path('t/data/foo.html'))));
        };
    }
    
}


sub run_tests {
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
