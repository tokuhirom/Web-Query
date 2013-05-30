requires 'HTML::Entities';
requires 'HTML::Selector::XPath', '0.06';
requires 'HTML::TreeBuilder::XPath', '0.12';
requires 'LWP::UserAgent', '6';
requires 'Scalar::Util';
requires 'parent';
requires 'perl', '5.008005';

on test => sub {
    requires 'Test::More', '0.98';
};
