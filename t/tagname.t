use strict;
use warnings;

use Test::More tests => 2;

use Web::Query;
use Web::Query::LibXML;

my $wq = Web::Query->new_from_html(<<'END');
<div><p><b>hello</b></p><p>there</p></div>
END

$wq->find('p')->each(sub{ $_->tagname('q') });

is $wq->as_html, '<div><q><b>hello</b></q><q>there</q></div>', 'p -> q';

$wq = Web::Query::LibXML->new_from_html(<<'END');
<div><p><b>hello</b></p><p>there</p></div>
END

$wq->find('p')->each(sub{ $_->tagname('q') });

is $wq->as_html, '<div><q><b>hello</b></q><q>there</q></div>', 'p -> q';

