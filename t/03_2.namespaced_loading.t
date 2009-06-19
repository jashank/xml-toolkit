#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use XML::Toolkit::Builder ();
use XML::Toolkit::Loader ();

my $xml1 = '<root xmlns="abc">test1</root>';
my $xml2 = '<my:root xmlns:my="abc">test2</my:root>';

my $args={
    namespace_map => { 'abc' => 'ABC' }
};

eval {
    my $builder = XML::Toolkit::Builder->new($args);
    $builder->parse_string($xml2);
    my $code = $builder->render();
    eval $code;
    my $root = ABC::Root->new();
    isa_ok($root, 'ABC::Root');
};

eval {
    my $loader = XML::Toolkit::Loader->new($args);
    $loader->parse_string($xml1);
    my $root = $loader->root_object;
    isa_ok($root,'ABC::Root');
    ok($root->text eq 'test1', 'root node text was not loaded correctly');
};

eval {
    my $loader = XML::Toolkit::Loader->new($args);
    $loader->parse_string($xml2);
    my $root = $loader->root_object;
    isa_ok($root,'ABC::Root');
    ok($root->text eq 'test2', 'root node text was not loaded correctly');
};
