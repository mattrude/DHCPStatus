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

package Formatted_text;

#
# This package allows display information to be formatted, or marked up.
# Format info is supplied by the module that generates the data.  Its up to
# the display module to determine how (or if) to make use of the format info.
#

use strict;

sub new {
   my $ft = {};
   $ft->{TEXT} = "";
   $ft->{HREF} = "";
   $ft->{HREF_PARMS} = ();
   $ft->{BOLD} = 0;
   bless($ft);
   return($ft);
}

#
# Our raw data.
#
sub text {
   my $ft = shift;
   $ft->{TEXT} = shift if (@_);
   return($ft->{TEXT});
}

#
# Pointer info (eg. a link to another web page; another program to be called).
#
sub href {
   my $ft = shift;
   $ft->{HREF} = shift if (@_);
   return($ft->{HREF});
}

sub href_parm {
   my $ft = shift;
   while (@_) {
      my $key = shift;
      my $value = shift;
      push(@{$ft->{HREF_PARMS}}, [$key, $value]);
   }
}
 
sub href_parm_count {
   my $ft = shift;
   return $#{$ft->{HREF_PARMS}};
}
 
sub get_href_parm {
   my $ft = shift;
   my $index = shift;
   my ($key, $value);
   ($key, $value) = @{$ft->{HREF_PARMS}[$index]};
   return($key, $value);
}

#
# Should we emphasise this data in some way (eg. bold, uppercase) ?
# 0 = no, 1 = yes.
#
sub bold {
   my $ft = shift;
   $ft->{BOLD} = shift if (@_);
   return($ft->{BOLD});
}

1;
