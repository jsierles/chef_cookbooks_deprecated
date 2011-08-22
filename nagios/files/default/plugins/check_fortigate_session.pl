#! /usr/bin/perl -w
#
# check_fortigate_session - nagios plugin 
#
# Description: plugin to query a Fortigate firewall and report 
# the number of sessions
#
##
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#
# Report bugs to: msullivan101@gmail.com
#
# This plugin is based on existing work from warrious users. 
# No liability

use POSIX;
use strict;
# Update the following value to reflect your install
use lib "/usr/lib/groundwork/nagios/script_securalis"  ;
use lib "/usr/local/groundwork/nagios/libexec"  ;
use lib "/usr/lib/nagios/plugins/";
use utils qw($TIMEOUT %ERRORS &print_revision &support);

use Net::SNMP;
use Getopt::Long;
&Getopt::Long::config('bundling');

my $PROGNAME = "check_fortigate_session";
my $status;

my $state = "UNKNOWN";
my $answer = "";
my $snmpkey = 0;
my $community = "public";
my $port = 161;
my @snmpoids;
my $snmpnsResSessActive = '.1.3.6.1.4.1.12356.1.10.0';;
my $hostname;
my $session;
my $error;
my $response;
my $snmp_version = 2 ;
my $opt_h ;
my $opt_w = 40 ;
my $opt_c = 60;
my $opt_V ;
my $session_used=0;


# Just in case of problems, let's not hang Nagios
$SIG{'ALRM'} = sub {
     print ("ERROR: No snmp response from $hostname (alarm)\n");
     exit $ERRORS{"UNKNOWN"};
};
alarm($TIMEOUT);


$status = GetOptions(
			"V"   => \$opt_V, "version"    => \$opt_V,
			"w=i"   => \$opt_w, "warning=i"    => \$opt_w,
			"c=i"   => \$opt_c, "critical=i"    => \$opt_c,
			"h"   => \$opt_h, "help"       => \$opt_h,
			"v=i" => \$snmp_version, "snmp_version=i"  => \$snmp_version,
			"C=s" =>\$community, "community=s" => \$community,
			"p=i" =>\$port,  "port=i",\$port,
			"H=s" => \$hostname, "hostname=s" => \$hostname);


				
if ($status == 0)
{
	print_help();
	exit $ERRORS{'OK'};
}
  
if ($opt_V) {
	print_revision($PROGNAME,'$Revision: 1.1 $ ');
	exit $ERRORS{'OK'};
}

if ($opt_h) {
	print_help();
	exit $ERRORS{'OK'};
}

if (! utils::is_hostname($hostname)){
	usage();
	exit $ERRORS{"UNKNOWN"};
}


if ( $snmp_version =~ /[12]/ ) {
   ($session, $error) = Net::SNMP->session(
		-hostname  => $hostname,
		-community => $community,
		-port      => $port,
		-version	=> $snmp_version
	);

	if (!defined($session)) {
		$state='UNKNOWN';
		$answer=$error;
		print ("$state: $answer");
		exit $ERRORS{$state};
	}
}elsif ( $snmp_version =~ /3/ ) {
	$state='UNKNOWN';
	print ("$state: No support for SNMP v3 yet\n");
	exit $ERRORS{$state};
}else{
	$state='UNKNOWN';
	print ("$state: No support for SNMP v$snmp_version yet\n");
	exit $ERRORS{$state};
}



push(@snmpoids,$snmpnsResSessActive);

   if (!defined($response = $session->get_request(@snmpoids))) {
      $answer=$session->error;
      $session->close;
      $state = 'CRITICAL';
      print ("$state: $answer\n");
      exit $ERRORS{$state};
   }

if($snmpnsResSessActive ne 0) {$session_used = $response->{$snmpnsResSessActive};}
   $answer = sprintf("Active Sessions : %s \n", 
      $response->{$snmpnsResSessActive},
      $session_used
   );

   $session->close;

   if ( $session_used <= $opt_w ) {
      $state = 'OK';
   }
   else {
    if ( $session_used <= $opt_c ) {
	$state = 'WARNING';
	} else {
	$state = 'CRITICAL';	
	}
   }

print ("$state: $answer");
exit $ERRORS{$state};


sub usage {
  printf "\nMissing arguments!\n";
  printf "\n";
  printf "usage: \n";
  printf "$PROGNAME -H <HOSTNAME> [-C <community>] [-w warning] [-c critical]\n";
  printf "For help, try: $PROGNAME -h \n";
  printf "Copyright (C) 2007 Matt Sullivan\n";
  printf "$PROGNAME comes with ABSOLUTELY NO WARRANTY\n";
  printf "This programm is licensed under the terms of the ";
  printf "GNU General Public License\n(check source code for details)\n";
  printf "\n\n";
  exit $ERRORS{"UNKNOWN"};
}

sub print_help {
	printf "$PROGNAME plugin for Nagios monitors the number of  \n";
  	printf "sessions for a Fortigate host\n";
	printf "\nUsage:\n";
	printf "   -H (--hostname)   Hostname to query - (required)\n";
	printf "   -C (--community)  SNMP read community (defaults to public,\n";
	printf "                     used with SNMP v1 and v2c\n";
	printf "   -v (--snmp_version)  1 for SNMP v1 (default)\n";
	printf "                        2 for SNMP v2c\n";
	printf "                        SNMP v2c will use get_bulk for less overhead\n";
	printf "                        if monitoring with -d\n";
	printf "   -p (--port)       SNMP port (default 161)\n";
	printf "   -V (--version)    Plugin version\n";
	printf "   -h (--help)       usage help \n\n";
	print_revision($PROGNAME, '$Revision: 1.1 $');
	
}
