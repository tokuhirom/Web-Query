# see https://github.com/tokuhirom/Web-Query/issues/47

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use WQTest;

my $html = <<'HTML';
<html>
    <p>Hello</p>
    <p>World</p>
</html>
HTML

WQTest::test {
    my $q = $_[0]->new($html);

    isa_ok $q, 'Web::Query';

    my @text;
    my @contents;

    $q->find('p')->each(sub {
        my ($i, $elem) = @_;
        push @text, $elem->text;
        push @contents, $elem->contents;
    });

    is_deeply \@text, [qw/ Hello World /], 'elements';

    is @contents, 2, 'two contents';

    isa_ok $_, 'Web::Query' for @contents;;

    is $contents[0]->text => 'Hello';
    is $contents[1]->text => 'World';
};
