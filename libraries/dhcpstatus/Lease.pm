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

package Lease;

#
# This package keeps track of the lease information for a single IP address.
#

use strict;

sub new {
   my $lease = {};
   $lease->{IP} = "";
   $lease->{STARTS} = 0;
   $lease->{ENDS} = "Never";
   $lease->{ETHERNET} = "";
   $lease->{UID} = "";
   $lease->{WINS} = "";
   $lease->{DNS} = "";
   $lease->{ABANDONED} = 0;
   bless($lease);
   return($lease);
}

#
# The IP address of this lease.
#
sub ip {
   my $lease = shift;
   if (@_) {
      $lease->{IP} = shift;
   }
   return($lease->{IP});
}

#
# This is a private member, hence the leading underscore in the name.  It is
# used to convert a date and a time string to epoch time.
#
sub _lease_time {
   require('timelocal.pl');
   my $yyyymmdd = shift;
   my $hhiiss = shift;
   my ($yyyy, $mm, $dd, $hh, $ii, $ss);
   ($yyyy, $mm, $dd) = split(/\//,$yyyymmdd);
   ($hh, $ii, $ss) = split(/:/, $hhiiss);
   $mm--;
   my $time = &timegm($ss, $ii, $hh, $dd, $mm, $yyyy);
   return($time);
}

sub starts {
   my $lease = shift;
   if ($#_ >= 1) {
      my $yyyymmdd = shift;
      my $hhiiss = shift;
      $lease->{STARTS} = &_lease_time($yyyymmdd, $hhiiss);
   }
   return($lease->{STARTS});
}

sub ends {
   my $lease = shift;
   if ($#_ >= 1) {
      my $yyyymmdd = shift;
      my $hhiiss = shift;
      $lease->{ENDS} = &_lease_time($yyyymmdd, $hhiiss);
   }
   return($lease->{ENDS});
}

sub ethernet {
   my $lease = shift;
   if (@_) {
      $lease->{ETHERNET} = shift;
   }
   return($lease->{ETHERNET});
}

sub uid {
   my $lease = shift;
   if (@_) {
      $lease->{UID} = shift;
   }
   return($lease->{UID});
}

sub wins {
   my $lease = shift;
   if (@_) {
      $lease->{WINS} = shift;
   }
   return($lease->{WINS});
}

sub dns {
   my $lease = shift;
   if (@_) {
      $lease->{DNS} = shift;
   }
   return($lease->{DNS});
}

#
# Boolean that returns TRUE if the lease is abandoned, FALSE otherwise.
#
sub abandoned {
   my $lease = shift;
   if (@_ && ($_[0] == 0 || $_[0] == 1)) {
      $lease->{ABANDONED} = shift;
   }
   return($lease->{ABANDONED});
}

#
# Boolean that returns TRUE if the lease has expired, FALSE otherwise.
#
sub ended {
   my $lease = shift;
   return(0) if $lease->ends eq "Never";
   return(1) if time() > $lease->ends;
   return(0);
}

#
# Boolean that returns TRUE if the lease is either abandoned or expired,
# FALSE otherwise.
#
sub active {
   my $lease = shift;
   return(!($lease->abandoned || $lease->ended));
}

1;
