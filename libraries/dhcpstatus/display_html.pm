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

sub display_html {

#
# Take a Display object, and print out the information as HTML.
#

   use CGI qw/:standard *table start_ul/;

   my $display = shift;

   my $q = new CGI;

   print $q->header;
   my $title = $display->title;
   print $q->start_html($title);
   print $q->h1({-align=>'center'}, $title);

   my $parm_count = $display->parm_count;		# parms (if any) are
   if ($parm_count >= 0) {				# printed first.
      print $q->start_table;
      for (my $row = 0; $row <= $parm_count; $row++) {
         my @parm = $display->get_parm($row);
         $parm[0] .= ":";
         print $q->Tr;
         print $q->td([@parm]);
      }
      print $q->end_table;
   }

   print $q->p;

   print $q->start_table({-border=>1});
   my @headings = $display->headings;
   print $q->Tr([th([@headings])]);
   my $row_count = $display->row_count;
   for (my $i = 0; $i <= $row_count; $i++) {	# print the tabular info row
      my @row = $display->get_row($i);		# by row.
      print $q->Tr;
      for (my $j = 0; $j <= $#row; $j++) {
         my $td;
         if (! defined($row[$j])) {
            $row[$j] = "";
         }
         if (ref($row[$j]) eq "Formatted_text") {	# if a row element
            $td = $row[$j]->text;			# contains formatted
            my $href = $row[$j]->href;			# text, then deal with
            $href = $q->self_url if ($href eq ".");	# it appropriately.
            if ($href ne "") {
               my $href_parm_count = $row[$j]->href_parm_count;
               if ($href_parm_count >= 0) {
                  $href .= "\?";
                  for (my $p = 0; $p <= $href_parm_count; $p++) {
                     my $key;
                     my $value;
                     ($key, $value) = $row[$j]->get_href_parm($p);
                     $href .= "$key=$value";
                     $href .= "\&" if ($p < $href_parm_count);
                  }
               }
               $td = $q->a({href=>$href},$td)
            }
            if ($row[$j]->bold) {
               $td = $q->b($td);
            }
         }
         else {
            $td = $row[$j];
         }
         $td = "&nbsp;" if ($td eq "");
         print $q->td([$td]);
      }
   }
   print $q->end_table;
   
   print $q->end_html;
}

1;
