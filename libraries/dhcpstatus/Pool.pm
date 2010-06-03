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

package Pool;

#
# This package is used to store the information about a single pool.  At the
# moment, only pool IP range info is stored.  Ranges are passed to us as an
# array containing the start and end IP address of the range.  The way ranges
# are stored is a bit of a hack at the moment - the first IP address is a
# hash key, and the final address is the corresponding hash value.  Ideally
# this stuff should be stored in anonymous arrays, but its late on a Sunday
# night and I can't be bothered right now.  At least the hack is hidden from
# the caller.
#

use strict;

sub new {
   my $pool = {};
   $pool->{RANGES} = {};
   bless($pool);
   return($pool);
}

sub add_range {
   my $pool = shift;
   my $ip_min = shift;
   my $ip_max = shift;
   $pool->{RANGES}{$ip_min} = $ip_max;
   return();
}

sub ranges_defined {
   my $pool = shift;
   my @ranges = keys(%{$pool->{RANGES}});
   return($#ranges);
}

sub get_range {
   my $pool = shift;
   my $i = shift;
   my @ranges = keys(%{$pool->{RANGES}});
   return($ranges[$i], $pool->{RANGES}{$ranges[$i]});
}

sub DESTROY {}

1;
