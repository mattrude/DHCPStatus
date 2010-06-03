#!/usr/bin/perl -w

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

use strict;

use lib "/usr/local/dhcpstatus";
my $dhcpstatus_dir = $INC[0];

use dhcpstatus::dhcpstatus_cgi;
use dhcpstatus::dhcpstatus_subnet_cgi;
use dhcpstatus::Dhcpstatus_env;

my $dhcpstatus_env = Dhcpstatus_env->new($dhcpstatus_dir);

my $subnet_id = &get_subnet_id_parm;
if (defined($subnet_id) && $subnet_id ne "") {
   &dhcpstatus_subnet_cgi($dhcpstatus_env, $subnet_id);
}
else {
   &dhcpstatus_cgi($dhcpstatus_env);
}
