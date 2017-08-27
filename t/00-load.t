#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'ManageWAR::Tomcat' ) || print "Bail out!\n";
}

diag( "Testing ManageWAR::Tomcat $ManageWAR::Tomcat::VERSION, Perl $], $^X" );
