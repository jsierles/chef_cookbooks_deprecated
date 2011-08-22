#!/usr/bin/env perl

use strict;

use Pod::Usage;
use Getopt::Long;
use HTTP::Request::Common qw(POST);
use HTTP::Status qw(is_client_error);
use LWP::UserAgent;
use File::Path;
use Fcntl qw(:flock);


=head1 NAME

pagerduty_nagios -- Send Nagios events to the PagerDuty alert system

=head1 SYNOPSIS

pagerduty_nagios enqueue [options]

pagerduty_nagios flush [options]

=head1 DESCRIPTION

  This script passes events from Nagios to the PagerDuty alert system. It's
  meant to be run as a Nagios notification plugin. For more details, please see
  the PagerDuty Nagios integration docs at:
  http://www.pagerduty.com/docs/nagios-integration.

  When called in the "enqueue" mode, the script loads a Nagios notification out
  of the environment and into the event queue.  It then tries to flush the
  queue by sending any enqueued events to the PagerDuty server.  The script is
  typically invoked in this mode from a Nagios notification handler.

  When called in the "flush" mode, the script simply tries to send any enqueued
  events to the PagerDuty server.  This mode is typically invoked by cron.  The
  purpose of this mode is to retry any events that couldn't be sent to the
  PagerDuty server for whatever reason when they were initially enqueued.

=head1 OPTIONS

  --api-base URL
    The base URL used to communicate with PagerDuty.  The default option here
    should be fine, but adjusting it may make sense if your firewall doesn't
    pass HTTPS traffic for some reason.  See the PagerDuty Nagios integration
    docs for details.

  --field KEY=VALUE
    Add this key-value pair to the event being passed to PagerDuty.  The script
    automatically gathers Nagios macros out of the environment, so there's no
    need to specify these explicitly.  This option can be repeated as many
    times as necessary to pass multiple key-value pairs.  This option is only
    useful when an event is being enqueued.0

  --help
    Display documentation for the script.

  --queue-dir DIR
    Path to the directory to use to store the event queue.  By default, we use
    /tmp/pagerduty_nagios.

  --verbose
    Turn on extra debugging information.  Useful for debugging.

=cut

my $opt_api_base = "http://events.pagerduty.com/nagios/2010-04-15";
my %opt_fields;
my $opt_help;
my $opt_queue_dir = "/tmp/pagerduty_nagios";
my $opt_verbose;


sub get_queue_from_dir {
	opendir(my $dh, $opt_queue_dir) || die $!;

	my @files;
	while (my $f = readdir($dh)) {
		next unless $f =~ /^pd_(\d+)_\d+\.txt$/;
		push @files, [int($1), $f];
	}

	closedir($dh);
	
	@files = sort { @{$a}[0] <=> @{$b}[0] } @files;
	return map { @{$_}[1] } @files;
}


sub flush_queue {
	my @files = get_queue_from_dir();
	my $ua = LWP::UserAgent->new;

	# It's not a big deal if we don't get the message through the first time.
	# It will get sent the next time cron fires.
	$ua->timeout(15);
	
	foreach (@files) {
		my $filename = "$opt_queue_dir/$_";
		my %event;

		print STDERR "==== Now processing: $filename\n" if $opt_verbose;
		
		open(my $fd, "<", $filename) || die $!;
		
		while (<$fd>) {
			chomp;
			my @fields = split("=", $_, 2);
			$event{$fields[0]} = $fields[1];
		}
		
		close($fd);

		my $req = POST("$opt_api_base/create_event", \%event);
		
		if ($opt_verbose) {
			my $s = $req->as_string;
			print STDERR "Request:\n$s\n";
		}
		
		my $resp = $ua->request($req);
		
		if ($opt_verbose) {
			my $s = $resp->as_string;
			print STDERR "Response:\n$s\n";
		}

		if ($resp->is_success) {
			print STDERR "Event accepted by the server\n" if $opt_verbose;
			unlink($filename);
		}
		elsif (is_client_error($resp->code)) {
			print STDERR "Event rejected by the server\n" if $opt_verbose;
			unlink($filename);
		}
		else {
			# Something else went wrong.
			print STDERR "Transient error while sending event\n" if $opt_verbose;
			return 0;
		}
	}

	# Everything that needed to be sent was sent.
	return 1;
}


sub lock_and_flush_queue {
	# Serialize access to the queue directory while we flush.
	# (We don't want more than one flush at once.)
	
	my $lock_filename = "$opt_queue_dir/lockfile";
	open(my $lock_fh, ">", $lock_filename) || die $!;
	flock($lock_fh, LOCK_EX) || die $!;
	
	my $ret = flush_queue();
	
	close($lock_fh);
	
	return $ret;
}


sub enqueue_event {
	my %event;

	# Scoop all the Nagios related stuff out of the environment.
	while ((my $k, my $v) = each %ENV) {
		next unless $k =~ /^NAGIOS_(.*)$/;
		$event{$1} = $v;
	}

	# Apply any other variables that were passed in.
	%event = (%event, %opt_fields);
	
	# Right off the bat, enqueue the event.  Nothing tiem consuming should come
	# before here (i.e. no locks or remote connections), because we want to
	# make sure we get the event written out within the Nagios notification
	# timeout.  If we get killed off after that, it isn't a big deal.
	
	my $filename = sprintf("$opt_queue_dir/pd_%u_%u.txt", time(), $$);
	open(my $fh, ">", $filename) || die $!;
	
	while ((my $k, my $v) = each %event) {
		# "=" can't occur in the keyname, and "\n" can't occur anywhere.
		# (Nagios follows this already, so I think we're safe)
		print $fh "$k=$v\n";
	}
	
	close($fh);
}

###########

GetOptions("api-base=s" => \$opt_api_base,
		   "field=s%" => \%opt_fields,
		   "help" => \$opt_help,
		   "queue-dir=s" => \$opt_queue_dir,
		   "verbose" => \$opt_verbose
		  ) || pod2usage(2);

pod2usage(2) if @ARGV < 1 ||
	 (($ARGV[0] ne "enqueue") && ($ARGV[0] ne "flush"));
	 
pod2usage(-verbose => 3) if $opt_help;


# This function automatically terminates the program on things like permission
# errors.
mkpath($opt_queue_dir);

if ($ARGV[0] eq "enqueue") {
	enqueue_event();
	lock_and_flush_queue();
}
elsif ($ARGV[0] eq "flush") {
	lock_and_flush_queue();
}
