#!/usr/bin/perl -w
# $Header$
# # ============================================================================
# # 
# #
# #       This program is free software; you can redistribute it and/or modify it
# #       under the terms of the GNU General Public License as published by the
# #       Free Software Foundation; either version 2, or (at your option) any
# #       later version.
# #
# #       This program is distributed in the hope that it will be useful,
# #       but WITHOUT ANY WARRANTY; without even the implied warranty of
# #       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# #       GNU General Public License for more details.
# #
# #       You should have received a copy of the GNU General Public License
# #       along with this program; if not, write to the Free Software
# #       Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
# #
# # ============================================================================
# #
# #       Description:

=head1 DESCRIPTION 

check_cisco.pl : SNMP check for cisco devices (routers/switches) returning state of different interfaces.

=cut

=head1 USAGE

 ./check_cisco.pl -h ip -c community -i interface -s state (optional)

=cut

#
#
# ============================================================================
#
# ==============================================================================
# # How using it ?
# ============================================================================
# ============================================================================
#

=head2 Options

C<-h or --host> : Set here the ip of your host

C<-c or --community> : Set here your own community

C<-i or --interface> : Set here the interface u want to check (Use the same syntax as for cisco devices, for exemple FastEthernet1/0/1, Fa2/0/3 or Fa0)

C<-s or --state> : Set the state of your interface. Options are : up/down/dormant

=head3 IMPORTANT:

snmp must be installed to perform snmpget/snmpwalk AND snmp server must be activated on your cisco device (switch or router)

=cut

=cut

=head2 Example

Wanna check Fa2/0/1 is up on your switch ?

./check_cisco.pl -h 192.168.0.1 -c public -i Fa2/0/1
or
./check_cisco.pl -h 192.168.0.1 -c public -i FastEthernet2/0/1

To check your FastEthernet0 is down on your router :

./check_cisco.pl -h 192.168.0.1 -c MyCommunity -i FastEthernet0 (or Fa0) -s down

To check your Backup RNIS BRIO:1 is dormant on your router:

./check_cisco.pl -h 192.168.0.1 -c MyCommunity -i BRI0:1 -s down

State option are : up (-s up), down (-s down), dormant (-s dormant). State is set to up if not defined.

Have FuN

=cut
#


#
## ============================================================================
#
###################Setting up some parameters#########################
use strict;
use Getopt::Long;

my $UNKNOW = -1;
my $OK = 0;
my $WARNING = 1;
my $CRITICAL = 2;
my $state = "up";
my $host = "127.0.0.1";
my $community = "public";
my $warning = "1000";
my $critical = "2000";
my $interface = "Vlan1";
my $oid="0";
my $MIBifDescr="IF-MIB::ifDescr";
my $MIBifOper="IF-MIB::ifOperStatus";
my $MIBifName="IF-MIB::ifName";
my $MIBifLastChange="IF-MIB::ifLastChange";
my $MIBTrafficIn="IF-MIB::ifInOctets";
my $MIBTrafficOut="IF-MIB::ifOutOctets";
my $MIBDescription="IF-MIB::ifAlias";
###################Getting options##############################
GetOptions(
        "host|h=s" => \$host,
        "community|c=s"  => \$community,
	"interface|i=s"   => \$interface,
	"state|s=s"	=>\$state
);
chomp($host);
chomp($community);
chomp($interface);
chomp($state);
#################################################################
			
my $walkDescr = snmpwalkgrep($host, $community, $MIBifDescr, $interface);
my $walkName = snmpwalkgrep($host, $community, $MIBifName, $interface);

if ($walkDescr =~ /$interface/ or $walkName =~ /$interface/){
	if ($walkDescr =~ /ifDescr.([0-9]+)/ || $walkName =~ /ifName.([0-9]+)/){
		my $oid =$1;
		#print "$oid\n";
		my $tree="IF-MIB::ifOperStatus.$oid";
		my $return=snmpwalk($host, $community, $tree);
		if ($return =~ /up/ && $state eq "up"){
			my $LastChange= snmpwalk($host, $community, "$MIBifLastChange"."\.".$oid);
			my $Alias= snmpwalk($host, $community, "$MIBDescription"."\.".$oid);
			my $TrafficIn =snmpwalk($host, $community, "$MIBTrafficIn"."\.".$oid);
			my $TrafficOut=snmpwalk($host, $community, "$MIBTrafficOut"."\.".$oid);
			my $LastChangeCleaned=CleanMe($LastChange); 
			my $AliasCleaned=CleanMe($Alias);
			my $TrafficInCleaned=CleanMe($TrafficIn);
			my $TrafficOutCleaned=CleanMe($TrafficOut);
			print "$interface up: $AliasCleaned, LastChanges: $LastChangeCleaned, Traffic in : $TrafficInCleaned octets, out: $TrafficOutCleaned octets\n";
			exit $OK;		
			
		}elsif ($return =~ /down/ && $state eq "up"){
			print "$interface is down\n";
			exit $CRITICAL;
		}elsif($return =~ /down/ && $state eq "down"){
			print "$interface down : ok\n";
			exit $OK;
		}elsif($return =~ /up/ && $state eq "down"){
			print "$interface should not be up\n";
			exit $CRITICAL;
		}elsif($return =~ /dormant/ && $state eq "down" || $return =~ /dormant/ && $state eq "up"){
			print "Error : $interface is sleeping\n";
			exit $CRITICAL;
		}elsif($return =~ /dormant/ && $state eq "dormant"){
			print "$interface is sleeping : ok\n";
			exit $OK
		}elsif($return =~ /up/ && $state eq "dormant"){
			print "$interface is up and should be sleeping\n";
			exit $CRITICAL;
		}else{
			print "Unknown state for $interface : check your -s state syntax\n";
			exit $UNKNOW;
		}
		
	}else{
	print "Not supported\n";
	exit $UNKNOW;
	}	
}else{
	print "Interface not found : please check your syntax for this device\n"; 
	exit $UNKNOW;
}

sub CleanMe
{
	my $input=$_[0];
	if ($input =~ /: (.*)/){
	my $return=$1;
	chomp($return);
	return $return;
}


}

sub snmpwalk
{
	my ($host, $community, $tree)=@_;
	my $walk = `snmpwalk -v 1 -c $community $host $tree`;
	chomp($walk);
	return $walk;
}

sub snmpwalkgrep
{
	my ($host, $community, $tree, $interface)=@_;
	my $walk = `snmpwalk -v 1 -c $community $host $tree |grep $interface`;
	chomp($walk);
	return $walk;
}

sub snmpget
{
	my ($host, $community, $tree)=@_;
	my $get = `snmpget -v 1 -c $community $host $tree`;
	chomp($get);
	return $get;
}


# ============================================================================
 #
=head1 AUTHORS

by R3dl!GhT 

=cut


=head1 COPYRIGHT

 Copyright (C) R3dL!GhT 2007.

This module is free software; you can redistribute it and/or
modify it under the terms of the GNU Public License.

=cut
# ============================================================================
#
# __END__
#

