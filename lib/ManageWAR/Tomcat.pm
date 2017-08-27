package ManageWAR::Tomcat;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request::Common;
use Exporter;

our @ISA = qw/Exporter/;
our @EXPORT = qw/save_cfg remove_cfg read_cfg deploy undeploy start check stop/;

our $VERSION = '0.02';



sub save_cfg {
	my (%cfg) = @_;

	die "configuration name is not set" unless $cfg{config};
	open my $fh, '>', $cfg{config} or die "can not open file '$cfg{config}': $!";
	for my $p (qw/user password hostname app_path lang/) {
		print $fh "$p: $cfg{$p}\n" if $cfg{$p};
	}
	close $fh or die "error during close file '$cfg{config}': $!";

	return 1;
}



sub remove_cfg {
	my (%cfg) = @_;

	die "configuration file '$cfg{config}' not found" unless -f $cfg{config};
	unlink $cfg{config} or die "error during unlink file '$cfg{config}': $!";

	return 1;
}



sub read_cfg {
	my (%cfg) = @_;

	open my $fh, '<', $cfg{config} or die "can not open file '$cfg{config}': $!";
	while (<$fh>) {
		chomp;
		next unless /^(\w+):\s*(.+)/;
		# command line arguments override ones from a config file
		$cfg{$1} = $2 unless $cfg{$1};
	}
	close $fh or die "error durinng closing file '$cfg{config}': $!";

	return %cfg;
}



sub _check_params {
	my (%cfg) = @_;

	if ($cfg{action} eq 'deploy') {
		die "no application to deploy" unless $cfg{application};
	} else {
		die "no application path" unless $cfg{app_path};
	}
	die "no hostname" unless $cfg{hostname};
	die "no user or no password" if $cfg{action} ne 'check' and (not $cfg{user} or not $cfg{password});

	return 1;
}



sub check {
	my (%cfg) = @_;

	_check_params %cfg;

	my $ua = new LWP::UserAgent;
	my $request = GET "http://$cfg{hostname}/$cfg{app_path}";
	my $response = $ua->request($request);
	if ($response->is_error) {
		print "FAIL - Application at context path /$cfg{app_path} is not available\n";
	} else {
		print "OK - Application at context path /$cfg{app_path} is available\n";
	}

	return 1;
}



sub deploy {
	my (%cfg) = @_;

	unless ($cfg{app_path}) {
		$cfg{app_path} = $cfg{application};
		$cfg{app_path} =~ s/(.*\/)?(.+)\.war$/$2/i;
	}

	_check_params %cfg;

	my $ua = new LWP::UserAgent;
	my $request = PUT "http://$cfg{hostname}/manager/text/deploy?path=/$cfg{app_path}",
		Content => do {
			open my $fh, '<', $cfg{application} or die "can not open file '$cfg{application}': $!";
			local $/;
			my $content = <$fh>;
			close $fh or die "error during close file '$cfg{applocation}': $!";
			$content;
		};
	$request->authorization_basic($cfg{user}, $cfg{password});
	my $response = $ua->request($request);
	print $response->content;
	$cfg{action} = 'check';
	check %cfg;

	return 1;
}



sub _actions {
	my (%cfg) = @_;

	_check_params %cfg;

	my $ua = new LWP::UserAgent;
	my $request = GET "http://$cfg{hostname}/manager/text/$cfg{action}?path=/$cfg{app_path}";
	$request->authorization_basic($cfg{user}, $cfg{password});
	my $response = $ua->request($request);
	print $response->content;

	return 1;
}

sub undeploy {
	my (%cfg) = @_;
	$cfg{action} = 'undeploy';
	_actions %cfg;
	return 1;
}

sub start {
	my (%cfg) = @_;
	$cfg{action} = 'start';
	_actions %cfg;
	return 1;
}

sub stop {
	my (%cfg) = @_;
	$cfg{action} = 'stop';
	_actions %cfg;
	return 1;
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

=over

=item process_cfg

Processes configuration (from a file or command line arguments)

=item save_cfg

Saves current configuration to a file

=item remove_cfg

Removes current configuration

=item deploy

Deploy the application

=item undeploy

Undeploy the application

=item start

Start the application

=item check

Check if application's start page responds

=item stop

Stop the application

=back

=head1 AUTHOR

Sergey Kovalyov, C<< <sergey.kovalyov at gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ManageWAR::Tomcat

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Sergey Kovalyov.

=cut

1; # End of ManageWAR::Tomcat
