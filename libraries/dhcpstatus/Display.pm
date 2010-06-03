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

package Display;

#
# This package is a "holding" place for information to be displayed.  The info
# is stored here in a format that is independent of the user interface.  This
# Display object gets passed to a display_xxxx module, which outputs it in a
# particular format, eg. text, html, x-windows, xml, ...
# Because the display info is stored here in output-independent formats, its
# relatively easy to write new display modules (at least that's the theory).
#

use strict;

sub new {
   my $display = {};
   $display->{TITLE} = "";
   $display->{PARMS} = ();
   $display->{HEADINGS} = ();
   $display->{ROWS} = ();
   $display->{WIDTHS} = ();
   bless($display);
   return($display);
}

sub title {
   my $display = shift;
   if (defined($_[0])) { $display->{TITLE} = shift; }
   return($display->{TITLE});
}

#
# These parms are ordered key-value pairs of information, aimed at giving
# summary info to be displayed in the final output.
#
sub parm {
   my $display = shift;
   while (@_) {
      my $key = shift;
      my $value = shift;
      $value = "" if (! defined($value));
      push(@{$display->{PARMS}}, [$key, $value]);
   }
}

#
# Simple method to determine the number of parms defined.
#
sub parm_count {
   my $display = shift;
   return $#{$display->{PARMS}};
}

#
# Method to get the i-th parm.
#
sub get_parm {
   my $display = shift;
   my $index = shift;
   my ($key, $value);
   ($key, $value) = @{$display->{PARMS}[$index]};
   return($key, $value);
}

#
# Headings for the columns of the tabular data.
#
sub headings {
   my $display = shift;
   if (@_) {
      @{$display->{HEADINGS}} = @_;
   }
   return(@{$display->{HEADINGS}});
}

#
# A single row of tabular data, stored as an array.
#
sub row {
   my $display = shift;
   push(@{$display->{ROWS}}, [@_]);
}

#
# How may rows have we got ?
#
sub row_count {
   my $display = shift;
   return($#{$display->{ROWS}});
}

#
# Give me the i-th row as an array.
#
sub get_row {
   my $display = shift;
   my $index = shift;
   my @row = @{$display->{ROWS}[$index]};
   for (my $i = 0; $i <= $#row; $i++) {
      $row[$i] = "" if (! defined($row[$i]));
   }
   return(@row);
}

#
# This was an idea for providing width info for columns in the final output,
# but isn't used at the moment.
#
sub widths {
   my $display = shift;
   if (@_) {
      @{$display->{WIDTHS}} = @_;
   }
   return(@{$display->{WIDTHS}});
}

1;
