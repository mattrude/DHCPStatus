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

sub dhcpstatus_subnet_cmd {

use dhcpstatus::common;
use dhcpstatus::dhcpstatus_subnet;
use dhcpstatus::Subnet;
use dhcpstatus::Display;
use dhcpstatus::Formatted_text;
use dhcpstatus::display_line;

   my $dhcpstatus_env = shift;
   my $subnet_id = shift;

# Extract all the symbols from the dhcpd.conf file.
   my @conf_sym = &get_symbols($dhcpstatus_env->conf_file);

# Get the conf details about our subnet.
   my $subnet = &get_one_subnet($subnet_id, 0, \@conf_sym);

# Extract all the symbols from the dhcpd.leases file.
   my @lease_sym = &get_symbols($dhcpstatus_env->leases_file);

# Make a hash of leases (keyed by IP address) of all active IP addresses in
# the subnet range.
   my %lease = &get_active_leases($subnet->ip_min, $subnet->ip_max, @lease_sym);

   my $display = &correlate_subnet($dhcpstatus_env->title.": ".$subnet->comment,
                                   $subnet,
                                   \%lease,
                                   $dhcpstatus_env->show_whole_subnet);

   &display_line($display, $dhcpstatus_env);
}

1;
