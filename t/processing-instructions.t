use strict;
use warnings;

use lib 't/lib';

use Test::More;

use WQTest;

my $doc = <<'END';
<div>
    <?xml-stylesheet type="text/css" href="style.css"?>
    <p>stuff</p>
    <h1>alpha</h1>
        <p>aaa</p>
</div>
END

WQTest::test {
    my $class = shift;

    plan skip_all => "not working for $class"
        if $class eq 'Web::Query';

    like $class->new($doc)->find(\"//processing-instruction('xml-stylesheet')")->as_html
        => qr/style.css/;

}
