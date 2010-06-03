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

package Line_print;

#
# This package allows plain text to be written line-by-line, in a controlled
# way.  In particular, we keep track of how many characters of text are
# written, and compare it with our output line width, to make sure that
# stuff doesn't wrap over a line in an ugly way.
# This package is used by the display_line.pm module.  Its worth noting here
# that display_line.pm makes use of the Term::ReadKey module if its installed
# to determine how wide the output should be.  If Term::ReadKey isn't installed,
# then display_line.pm reads the width from the dhcpstatus.ini file.
#

use strict;

sub new {
   my $lp = {};
   $lp->{WIDTH} = 0;
   $lp->{BUFFER} = "";
   $lp->{SEPARATOR} = 4;
   bless($lp);
   return($lp);
}

#
# Width of text output.
#
sub width {
   my $lp = shift;
   if (@_) {
      $lp->{WIDTH} = shift;
   }
   return($lp->{WIDTH});
}

#
# How much space should we leave between "globs" of output text ?
#
sub separator {
   my $lp = shift;
   if (@_) {
      $lp->{SEPARATOR} = shift;
   }
   return($lp->{SEPARATOR});
}

#
# How many chars are in our current output buffer ?
#
sub buffer_length {
   my $lp = shift;
   my $buffer = $lp->{BUFFER};
   return(length($buffer));
}

#
# Print out the contents of the output buffer.
#
sub print_text {
   my $lp = shift;
   while (@_) {
      my $new_len = $lp->buffer_length + $lp->separator + length($_[0]);
      if ($new_len > $lp->width) {
         my $buffer = $lp->{BUFFER};
         print("$buffer\n");
         $lp->{BUFFER} = "";
      }
      elsif ($lp->buffer_length > 0) {
         $lp->{BUFFER} .= " " x $lp->{SEPARATOR};
      }
      $lp->{BUFFER} .= shift;
   }
   return($lp);
}

#
# Flush the output buffer.  This is similar to the print_text method, but we
# don't print anything if there's nothing in the buffer (in particular, new
# lines (\n) aren't printed without reason).
#
sub flush {
   my $lp = shift;
   if ($lp->buffer_length > 0) {
      my $buffer = $lp->{BUFFER};
      print("$buffer\n");
      $lp->{BUFFER} = "";
   }
   print("\n");
}

1;
