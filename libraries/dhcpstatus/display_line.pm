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

sub display_line {

#
# Take the information in a Display object, and print it out as plain text,
# line-by-line.
#

   use dhcpstatus::Line_print;

   my $display = shift;
   my $dhcpstatus_env = shift;

   my $title = $display->title;
   print("$title\n\n");

   my $parm_count = $display->parm_count;
   if ($parm_count >= 0) {
      for (my $row = 0; $row <= $parm_count; $row++) {
         my @parm = $display->get_parm($row);
         $parm[0] .= ":";
         print("$parm[0]\t$parm[1]\n");
      }
      print("\n");
   }


   my @headings = $display->headings;
   my $row_count = $display->row_count;
   my $screen_width = $dhcpstatus_env->screen_width;

   for (my $i = 0; $i <= $row_count; $i++) {
      my $lp = Line_print->new;
      $lp->width($screen_width);
      my @row = $display->get_row($i);
      for (my $j = 0; $j <= $#row; $j++) {
         next if (! defined($row[$j]));
         if (ref($row[$j]) eq "Formatted_text") {
            $row[$j] = $row[$j]->text;
            $row[$j] =~ tr/a-z/A-Z/;		# uppercase anything formatted.
         }
         next if ($row[$j] eq "");
         $lp->print_text($headings[$j].": ".$row[$j]);
      }
      $lp->flush;
   }
}

1;
