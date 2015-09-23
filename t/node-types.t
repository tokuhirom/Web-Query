use strict;
use warnings;

use Test::More;

use lib 't/lib';

use WQTest;

WQTest::test {
    my $class = shift;

    my $q = $class->new_from_html(<<'END');
        <html>
        <body>
        <x>
            one 
            <div><p>two</p></div>
            <!-- three -->
        </x>
        </body>
        </html>
END

        my $contents = $q->find('x')->contents;
        
        is $contents->find('p')->html => 'two', 'skip over text and comments';

        like $contents->filter(sub{ $_->tagname eq  '#text' })->as_html 
            => qr'one', '#text';

        like $contents->filter(sub{ $_->tagname eq  '#comment' })->as_html 
            => qr'three', '#comment';
}


