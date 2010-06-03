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

sub dhcpstatus_cmd {

use dhcpstatus::common;
use dhcpstatus::dhcpstatus;
use dhcpstatus::Formatted_text;
use dhcpstatus::Display;
use dhcpstatus::display_line;

   my $dhcpstatus_env = shift;

#
# Read the dhcpd.conf file, and extract the info as an array of "symbols".
#
   my @conf_sym = &get_symbols($dhcpstatus_env->conf_file);

#
# The %parms hash contains values for options and parameters.  We treat
# options and parms in exactly the same way.  Comments (lines starting with
# "#$") are put into this hash as well.
#
   my %parms;
   $parms{"comment"} = "";

#
# Take the array of symbols from the dhcpd.conf file, and extract all the
# subnet info out of it.
#
   my @subnet = &parse_conf_sym(\@conf_sym, %parms);

#
# Read dhcpd.leases to get an array of symbols.
#
   my @lease_sym = &get_symbols($dhcpstatus_env->leases_file);

#
# Get a list of IP addresses for leases that are still active.
#
   my %lease = &get_active_lease_ips(@lease_sym);

   my $display = &correlate($dhcpstatus_env->title, \@subnet, \%lease);

   &display_line($display, $dhcpstatus_env);
}

1;
