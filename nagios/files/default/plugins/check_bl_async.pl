#!/usr/bin/perl -w
#
# check_bl plugin for nagios
# $Revision: 1.1 $ 
# 
# Nagios plugin designed to warn you if you mail servers appear in one of the 
# many anti-spam 'blacklists'
#
# By Sam Bashton, Bashton Ltd
# bashton.com/content/nagios-plugins
#
# Updated by Mark Nagel, Willing Minds LLC
# - converted to use asynchronous lookups and list failures
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use strict;
use lib "/usr/lib/nagios/plugins";
use utils qw($TIMEOUT %ERRORS &print_revision &support);
use Net::DNS;
use vars qw($PROGNAME);
my ($verbose,$host),;
my ($opt_V,$opt_h,$opt_B,$opt_H,$opt_c);
$opt_V = $opt_h = $opt_B = $opt_H = $opt_c = '';
my $state = 'UNKNOWN';
sub print_help();
sub print_usage();

$PROGNAME = "check_bl";

$ENV{'BASH_ENV'}=''; 
$ENV{'ENV'}='';
$ENV{'PATH'}='';
$ENV{'LC_ALL'}='C';

use Getopt::Long;
Getopt::Long::Configure('bundling');
GetOptions(
  "version|V"       => \$opt_V,
  "help|h"          => \$opt_h,
  "hostname|H=s"    => \$opt_H,
  "blacklists|B=s"  => \$opt_B,
  "critical|c=i"    => \$opt_c,
);

# -h means display verbose help screen
if ($opt_h) { print_help(); exit $ERRORS{'OK'}; }

# -V means display version number
if ($opt_V) { 
  print_revision($PROGNAME,'$Revision: 1.0 $ '); 
  exit $ERRORS{'OK'}; 
}

# First check the hostname is OK..
unless ($opt_H) { print_usage(); exit $ERRORS{'UNKNOWN'}; }

if (! utils::is_hostname($opt_H)) {
  print "$opt_H is not a valid host name\n";
  print_usage();
  exit $ERRORS{"UNKNOWN"};
} else {
  # If the host contains letters we assume it's a hostname, not an IP
  if ($opt_H =~ /[a-zA-Z]/ ) {  
    $host = lookup($opt_H);
  }
  else {
    $host = $opt_H;
  }
}


# $opt_c is a count of the blacklists a mail server is in,
# after which state will be CRITICAL rather than WARNING
# By default any listing is CRITICAL
my $critcount = 0;
if ($opt_c) { $critcount = $opt_c };

# $opt_B is a comma seperated list of blacklists
$opt_B = shift unless ($opt_B);
unless ($opt_B) { print_usage(); exit -1 }
my @bls = split(/,/, $opt_B);

my %listed;
my %socket;

my $res = Net::DNS::Resolver->new;
my $lookupip = $host;
$lookupip =~
    s/([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})/$4.$3.$2.$1/;
for my $bl (@bls) {
    $socket{$bl} = $res->bgsend("$lookupip.$bl", 'A');
}

# watch for results to come in up to $TIMEOUT-2 seconds
my $start_time = time;
while (keys(%socket) and time - $start_time < ($TIMEOUT-2)) {
    for my $bl (keys(%socket)) {
	if ($res->bgisready($socket{$bl})) {
	    my $packet = $res->bgread($socket{$bl});
	    delete $socket{$bl};
    	    for my $rr ($packet->answer) {
	        if ($rr->address) {
		    $listed{$bl}++;
		}
	    }
	}
    }
}

if (keys(%listed) == 0) {
    $state = 'OK'
}
elsif (scalar(keys(%listed)) < $critcount) {
    $state = 'WARNING'
}
else {
    $state = 'CRITICAL'
}

my $unknown = "";
if (keys(%socket)) {
    $unknown = " (unknown: " . join(" ", sort(keys(%socket))) . ")";
}
if (%listed) {
    print "Listed at " . join(" ", sort(keys(%listed))) . "$unknown\n"; 
}
else {
    print "Not black-listed$unknown\n";
}

exit $ERRORS{$state};


########  Subroutines ==========================


sub print_help() {
  print_revision($PROGNAME,'$Revision: 1.0 $ ');
  print "\n";
  support();
}

sub print_usage () {
  print "Usage: \n";
  print " $PROGNAME -H host -B [blacklist1],[blacklist2] [-c critnum]\n";
  print " $PROGNAME [-h | --help]\n";
  print " $PROGNAME [-V | --version]\n";
}
