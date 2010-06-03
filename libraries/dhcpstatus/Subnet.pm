#------------------------------------------------------------------------
# Copyright (C) 2000 Michael Grubits.
#
# This file is part of DHCPStatus.
#
# DHCPStatus is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# DHCPStatus is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with DHCPStatus; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#------------------------------------------------------------------------

package Subnet;

#
# This package is used to store the information about a single subnet.
#

use strict;
use dhcpstatus::iptools;

sub new {
   my $subnet = {};
   $subnet->{SUBNET_ID} = "";
   $subnet->{NETMASK} = "";
   $subnet->{BROADCAST} = "";
   $subnet->{ROUTER} = "";
   $subnet->{DNS_SERVER} = "";
   $subnet->{WINS_SERVER} = "";
   $subnet->{IP_MIN} = "";
   $subnet->{IP_MAX} = "";
   $subnet->{IPS} = {};
   $subnet->{COMMENT} = " ";
   bless($subnet);
   return($subnet);
}

sub subnet_id {
   my $subnet = shift;
   if (@_) {
      $subnet->{SUBNET_ID} = shift;
   }
   return($subnet->{SUBNET_ID});
}

sub netmask {
   my $subnet = shift;
   if (@_) {
      $subnet->{NETMASK} = shift;
   }
   return($subnet->{NETMASK});
}

sub broadcast {
   my $subnet = shift;
   if (@_) {
      $subnet->{BROADCAST} = shift;
   }
   return($subnet->{BROADCAST});
}

sub router {
   my $subnet = shift;
   if (@_) {
      $subnet->{ROUTER} = shift;
   }
   return($subnet->{ROUTER});
}

sub dns_server {
   my $subnet = shift;
   if (@_) {
      $subnet->{DNS_SERVER} = shift;
   }
   return($subnet->{DNS_SERVER});
}

sub wins_server {
   my $subnet = shift;
   if (@_) {
      $subnet->{WINS_SERVER} = shift;
   }
   return($subnet->{WINS_SERVER});
}

#
# The following two members return the first and last IP addresses that are in
# the subnet range.  These values are calculated from the subnet and netmask
# values.
#
sub ip_min {
   my $subnet = shift;
   return(&num2ip(&ip2num($subnet->subnet_id) + 1));
}

sub ip_max {
   my $subnet = shift;
   return(&num2ip(&ip2num($subnet->subnet_id)
                  + 2**32 - 2 - &ip2num($subnet->netmask)));
}

#
# This hash keeps track of the IP addresses listed in the "range" statements
# for this subnet (ie. the DHCP pool for this subnet).
#
sub ips {
   my $subnet = shift;
   foreach my $ip (@_) {
      $subnet->{IPS}{$ip} = $ip;
   }
   return(keys(%{$subnet->{IPS}}));
}

#
# Return the number of elements in the IPS hash;  ie., the number of IP
# addresses in this subnet that are in the DHCP pool.
#
sub ips_defined {
   my $subnet = shift;
   my @ips = keys(%{$subnet->{IPS}});
   return($#ips + 1);
}

#
# Boolean function - returns TRUE if the address is in the DHCP pool, or
# FALSE otherwise.
#
sub ip_defined {
   my $subnet = shift;
   if (@_) {
      my $ip = shift;
      if (defined($subnet->{IPS}{$ip})) {
         return($subnet->{IPS}{$ip});
      }
   }
   return(0);
}

sub comment {
   my $subnet = shift;
   if (defined($_[0])) {
      $subnet->{COMMENT} = shift;
      $subnet->{COMMENT} =~ s/_/ /g;
   }
   return($subnet->{COMMENT});
}

sub DESTROY {}

1;
