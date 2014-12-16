use strict;
use warnings;

use Test::More tests => 1;

use Web::Query;

is( Web::Query->new_from_html(<<'END')->as_html, '<div><span><p> hello there </p></span></div>', 'spaces trimmed' );
<div> <span> <p> hello  there </p> </span> </div>
END

is( Web::Query->new_from_html(<<'END', {no_space_compacting => 1})->as_html, '<div><span><p> hello  there </p></span></div>', 'spaces left' );
<div> <span> <p> hello  there </p> </span> </div>
END


