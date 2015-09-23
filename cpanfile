requires "Exporter" => "0";
requires "HTML::Entities" => "0";
requires "HTML::Selector::XPath" => "0.06";
requires "HTML::TreeBuilder::LibXML" => "0";
requires "HTML::TreeBuilder::XPath" => "0";
requires "LWP::UserAgent" => "0";
requires "List::MoreUtils" => "0";
requires "Scalar::Util" => "0";
requires "parent" => "0";
requires "perl" => "5.008005";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Cwd" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "FindBin" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Test::Exception" => "0";
  requires "Test::More" => "0";
  requires "lib" => "0";
  requires "utf8" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
