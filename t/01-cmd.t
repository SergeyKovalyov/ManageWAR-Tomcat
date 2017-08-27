#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use Test::Output;
use ManageWAR::Tomcat;

my %cfg;
@cfg{qw/hostname user password application app_path/} = qw/192.168.0.4:8080 test_user1 user1pass hello-world.war test_path/;

my $re_str = '^(OK|FAIL) - .+';
stdout_like { $cfg{action} = 'deploy';   deploy %cfg }   qr/${re_str}${re_str}/sm;
stdout_like { $cfg{action} = 'stop';     stop %cfg }     qr/$re_str/;
stdout_like { $cfg{action} = 'start';    start %cfg }    qr/$re_str/;
stdout_like { $cfg{action} = 'check';    check %cfg }    qr/$re_str/;
stdout_like { $cfg{action} = 'undeploy'; undeploy %cfg } qr/$re_str/;

