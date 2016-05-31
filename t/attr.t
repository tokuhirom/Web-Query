use strict;
use warnings;
use utf8;
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

    subtest 'set many attrs at the same time' => sub {
        my $doc = wq( '<div>hi</div>' );

        $doc->attr(
            foo => 1,
            bar => 'baz',
        );

        is $doc->attr('foo') => 1, 'foo is set';
        is $doc->attr('bar') => 'baz', 'bar is set';
    };

    subtest 'code ref as setter' => sub {
        my $doc = wq( '<div><img /><img alt="kitten" /></div>' );

        $doc->find('img')->attr(alt => sub{ $_ ||= 'A picture' });

        is_deeply [ $doc->find('img')->attr('alt') ],
            [ 'A picture', 'kitten' ];
    }


}
