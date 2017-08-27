package ManageWAR::Tomcat;

use strict;
use warnings;
use autodie;

use LWP::UserAgent;
use HTTP::Request::Common;
use Exporter;

our @ISA = qw/Exporter/;
our @EXPORT = qw/%cfg save_cfg remove_cfg read_cfg deploy undeploy start check stop/;

our $VERSION = '0.01';
our %cfg;
our $ua = new LWP::UserAgent;



sub save_cfg {
	die "configuration name is not set" unless $cfg{config};
	open my $fh, '>', $cfg{config};
	for my $p (qw/user password hostname app_path lang/) {
		print $fh "$p: $cfg{$p}\n" if $cfg{$p};
	}
}



sub remove_cfg {
	die "configuration file '$cfg{config}' not found" unless -f $cfg{config};
	unlink $cfg{config};
}



sub read_cfg {
	die "configuration file '$cfg{config}' not found" unless -f $cfg{config};
	open my $fh, '<', $cfg{config};
	while (<$fh>) {
		chomp;
		next unless /^(\w+):\s*(.+)/;
		# command line arguments override ones from a config file
		$cfg{$1} = $2 unless $cfg{$1};
	}
}



sub _check_params {
	if ($cfg{action} eq 'deploy') {
		die "no application to deploy" unless $cfg{application} and -f $cfg{application};
	} else {
		die "no application path" unless $cfg{app_path};
	}
	die "no hostname" unless $cfg{hostname};
	die "no user or no password" unless $cfg{user} and $cfg{password};
}



sub check {
	die "no application path" unless $cfg{app_path};

	my $request = GET "http://$cfg{hostname}/$cfg{app_path}";
	my $response = $ua->request($request);
	if ($response->is_error) {
		print "FAIL - Application at context path /$cfg{app_path} is not available\n";
	} else {
		print "OK - Application at context path /$cfg{app_path} is available\n";
	}
}



sub deploy {
	_check_params();

	my $path;
	if ($cfg{app_path}) {
		$path = $cfg{app_path};
	} else {
		$path = $cfg{application};
		$path =~ s/\.war$//i;
	}
	my $request = PUT 'http://' . $cfg{hostname} . '/manager/text/deploy?path=/' . $path,
		Content => do { open my $fh, '<', $cfg{application}; local $/; <$fh> };
	$request->authorization_basic($cfg{user}, $cfg{password});
	my $response = $ua->request($request);
	print $response->content;
	check();
}



sub _actions {
	_check_params();

	my $request = GET "http://$cfg{hostname}/manager/text/$cfg{action}?path=/$cfg{app_path}";
	$request->authorization_basic($cfg{user}, $cfg{password});
	my $response = $ua->request($request);
	print $response->content;
}

sub undeploy {
	_actions();
}

sub start {
	_actions();
}

sub stop {
	_actions();
}



=head1 NAME

ManageWAR::Tomcat - module to manage WAR applications under Tomcat

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use ManageWAR::Tomcat;

    process_cfg();
    deploy();
    start();
    check();
    ...
    stop();

=head1 EXPORT

Exports action functions: process_cfg, save_cfg, remove_cfg, deploy, undeploy, start, check, stop

=head1 SUBROUTINES/METHODS

=head2 process_cfg

Processes configuration (from a file or command line arguments)

=head2 save_cfg

Saves current configuration to a file

=head2 remove_cfg

Removes current configuration

=head2 deploy

=head2 undeploy

=head2 start

=head2 check

=head2 stop

=head1 AUTHOR

Sergey Kovalyov, C<< <sergey.kovalyov at gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ManageWAR::Tomcat

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Sergey Kovalyov.

=cut

1; # End of ManageWAR::Tomcat
