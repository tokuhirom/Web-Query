use strict;
use warnings;

use Test::More tests => 3;

use Web::Query;

is( Web::Query->new_from_html(<<'END')->as_html, '<div><span><p> hello there </p></span></div>', 'spaces trimmed' );
<div> <span> <p> hello  there </p> </span> </div>
END

is( Web::Query->new_from_html(<<'END', {no_space_compacting => 1})->as_html, '<div><span><p> hello  there </p></span></div>', 'spaces left' );
<div> <span> <p> hello  there </p> </span> </div>
END

subtest 'LibXML' => sub {
    eval "require Web::Query::LibXML; 1" 
        or plan skip_all => "couldn't load Web::Query::LibXML";

    # LibXML doesn't trim by default

    is( Web::Query::LibXML->new_from_html(<<'END')->as_html, '<div> <span> <p> hello  there </p> </span> </div>' );
<div> <span> <p> hello  there </p> </span> </div>
END

    is( Web::Query::LibXML->new_from_html(<<'END', {no_space_compacting => 1})->as_html, '<div> <span> <p> hello  there </p> </span> </div>' );
<div> <span> <p> hello  there </p> </span> </div>
END
};


