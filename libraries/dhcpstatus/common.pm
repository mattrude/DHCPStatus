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

# This file contains all the subroutines that are used by both dhcpstatus.cgi
# and dhcpstatus_subnet.cgi.

#--------------------------------------------------------------------------
# These two subroutines allow for manipulation of IP addresses, as if
# they were integers.  &ip2num takes an IP address and returns the number
# between 0 and 2**32-1 that it represents.  &num2ip does the opposite.
# With these, we can do arithmetic on IP addresses, eg:
#
#   &num2ip(&ip2num("192.54.128.17") + 1)   gives   "192.54.128.18".
#
sub ip2num {
   my $ip = shift;
   my @hex = split('\.',$ip);
   my $num = $hex[0];
   foreach my $i (1, 2, 3) {
      $num <<= 8;
      $num += $hex[$i];
   }
   return($num);
}

sub num2ip {
   my $num = shift;
   my @hex;
   $hex[3] = $num & 255;
   foreach my $i (2, 1, 0) {
      $num >>= 8;
      $hex[$i] = $num & 255;
   }
   my $ip = join(".",@hex);
   return($ip);
}

#--------------------------------------------------------------------------
# The parm passed to this subroutine should be a string starting with
# the characters "#$".  This sub converts the white space in the string
# to underscores, and gets rid of some unwanted chars.  The prefixed
# "$" character is an indication to code further down the track that
# this is a comment describing a subnet.
#
sub get_comment {
   my $line = shift;
   $line = substr($line, 2);
   while (
           (length($line) > 0) &&
           (
             (substr($line, 0, 1) eq " ") ||
             (substr($line, 0, 1) eq "\t")
             )
         ) {
      $line = substr($line, 1);
   }
   while (
           (length($line) > 0) &&
           (
             (substr($line, length($line) - 1, 1) eq " ") ||
             (substr($line, length($line) - 1, 1) eq "\t") ||
             (substr($line, length($line) - 1, 1) eq "\n")
             )
         ) {
      chop($line);
   }
   $line = $line."\n";
   $line =~ s/ /_/g;
   $line =~ s/\t/_/g;
   $line =~ s/;/./g;
   $line =~ s/,/./g;
   $line =~ s/"//g;
   $line = "\$".$line;
   return($line);
}

#--------------------------------------------------------------------------
# Read all the lines in a file, throw away comment lines (ones starting with
# "#", and get a list of "symbols".
#
sub get_symbols {
   my $file;
   if ($#_ < 0) {
      $file = "/etc/dhcpd.conf";
   }
   else {
      $file = shift;
   }

   my @sym;
   open(FILE, $file) || die("Can't open $file\n");
   while (defined(FILE) && (my $line = <FILE>)) {
      my $comment_index = index($line, "#");	# does this line contain a
      if ($comment_index >= 0) {		# comment ?
         if (substr($line, 0, 2) eq '#$') {	# is it a subnet comment ?
            $line = &get_comment($line);
         }
         else {					# ignore everything after the
            $line = substr($line,0,$comment_index)."\n";	# "#" sign.
         }
      }
      $line =~ s/\n/ /g;
      $line =~ s/{/ { /g;
      $line =~ s/\t/ /g;
      $line =~ s/;/ ; /g;
      $line =~ s/,/ , /g;
      $line =~ s/"/ /g;

      push(@sym, split(' ', $line));
   }
   close(FILE);

   return(@sym);
}

#--------------------------------------------------------------------------
# Parse a parameter or an option, and return it as a key/value pair.  If there
# is more than one value, separate them by commas.  DHCP options and parameters
# are both treated the same way.  Things like "allow", "deny", etc. will
# hopefully be stored the same as a parameter, and eventually ignored, since
# I'm not interested in them.  Also, things like "blah blah { blah blah; }"
# are ignored.
#
sub get_value {
   my $symref = shift;

   if ($$symref[1] eq ";") {		# this takes care of single-word
      splice(@$symref, 0, 2);		# directives.
      return(0, 0);
   }
   for (my $i = 0; $i <= $#$symref; $i++) {	# this takes care of things
      last if ($$symref[$i] eq ";");		# like:
      if ($$symref[$i] eq "{") {		# blah blah { blah blah; }
         &ignore_statement($symref);		# which we aren't interested in
         return(0, 0);				# at least not in this version.
      }
   }
   shift(@$symref) if $$symref[0] eq "option";	# we'll treat options the same
   my $key = shift(@$symref);			# as parms.
   my $value = shift(@$symref);
   while (@$symref && ($$symref[0] ne ";")) {
      if ($$symref[0] eq ",") {
         shift(@$symref);
         next;
      }
      $value = $value.", ".shift(@$symref);
   }
   shift(@$symref);
   return($key, $value);
}

#--------------------------------------------------------------------------
# Take a "range" statement from within a subnet, and return an array of
# IP addresses that fall within that range.
#
sub get_range {
   my $symref = shift;

   shift(@$symref);				# move past "range" keyword.
   shift(@$symref) if $$symref[0] eq "dynamic-bootp";	# ditto dynamic-bootp.
   my $ip_min = shift(@$symref);
   if ($$symref[0] eq ";") {			# there was only 1 IP in range.
      shift(@$symref);				# semicolon.
      return($ip_min);
   }
   my $ip_max = shift(@$symref);		# the last IP in the range.
   shift(@$symref);				# semicolon.
   my $num_min = &ip2num($ip_min);
   my $num_max = &ip2num($ip_max);
   my @range;
   for (my $num = $num_min; $num <= $num_max; $num++) {
      push(@range, &num2ip($num));
   }
   return(@range);
}

#--------------------------------------------------------------------------
# Parse a "subnet" statement.  All the details about the subnet are stored
# in our "Subnet" object.
#
sub get_subnet {
   use dhcpstatus::Subnet;

   my $symref = shift;			# ref to the symbols from dhcpd.conf.
   my %parms = @_;			# parm values we inherit.

   my $subnet = Subnet->new;
   shift(@$symref);			# "subnet" keyword.
   my $subnet_id = shift(@$symref);	# the subnet.
   shift(@$symref);			# "netmask" keyword.
   my $netmask = (shift(@$symref));	# the netmask.
   while (shift(@$symref) ne "{") {}	# find opening brace (should be next).
   my $brace_count = 1;
   
   while ($brace_count > 0) {
      if ($$symref[0] eq "range") {		# add ip range info.
         my @range = &get_range($symref);
         $subnet->ips(@range);
         next;
      }
      if ($$symref[0] eq "pool") {
         shift(@$symref);			# move past pool keyword.
         shift(@$symref);			# move past opening brace.
         $brace_count++;
         next;
      }
      if (substr($$symref[0], 0, 1) eq "\$") {		# a comment about the
         $parms{"comment"} = substr($$symref[0], 1);	# subnet.
         shift(@$symref);
         next;
      }
      if ($$symref[0] eq "}") {			# closing brace, could be the
         shift(@$symref);			# end of the subnet defn, or
         $brace_count--;			# just the end of a pool.
         next;
      }
      my ($key, $value) = &get_value($symref);		# a parm/option.
      if ($brace_count == 1) {				# don't use the parm/
         $parms{$key} = $value;				# option if it applies
      }							# only to a pool.
      next;
   }
   
   $subnet->subnet_id($subnet_id);
   $subnet->netmask($netmask);
   $subnet->broadcast($parms{"broadcast-address"});
   $subnet->router($parms{"routers"});
   $subnet->dns_server($parms{"domain-name-servers"});
   $subnet->wins_server($parms{"netbios-name-servers"});
   $subnet->comment($parms{"comment"});

   return($subnet);
}

#--------------------------------------------------------------------------
# Parse a pool statement.  Info about this pool is put in a Pool object.  At
# the moment, the only thing we bother recording is IP ranges.

sub get_pool {

   use dhcpstatus::Pool;

   my $symref = shift;

   my $pool = Pool->new;
   while (shift(@$symref) ne "{") {}
   my $brace_count = 1;
   while ($brace_count > 0) {
      if ($$symref[0] eq "}") {
         $brace_count--;
         shift(@$symref);
         next;
      }
      if ($$symref[0] eq "range") {
         my @range = &get_range($symref);
         $pool->add_range($range[0], $range[$#range]);
         next;
      }
      &ignore_statement($symref);
   }
   return($pool);
}

#--------------------------------------------------------------------------
# Ignore a statement, because it contains stuff we don't support in this
# version.  A statement can be of the form:
#      blah blah blah blah blah;
# or :
#      blah blah { blah { blah blah } blah }
# ie. either a series of symbols terminated by a semicolon, or a series of
# symbols terminated by a brace-enclosed block (including any nested braces).
#
sub ignore_statement {
   my $symref = shift;

   my $brace_count = 0;
   while (my $sym = shift(@$symref)) {
      if ($sym eq ";") {
         return;
      }
      if ($sym eq "{") {
         $brace_count++;
         last;
      }
      next;
   }

   while (@$symref && ($brace_count > 0)) {
      my $sym = shift(@$symref);
      if ($sym eq "{") {
         $brace_count++;
      }
      elsif ($sym eq "}") {
         $brace_count--;
      }
   }
}

#--------------------------------------------------------------------------
# No, this subroutine is not an illegal activity.  It (along with pop_hash)
# is a way of implementing a stack of hashes by having an element in each
# hash reference the next hash in the stack.  A fair-enough idea, but maybe
# an ugly implementation.  Oh well, it works.
#
sub push_hash {
   my $hashref = shift;
   my $index = "__push_hash_index";

   my %newhash = %$hashref;
   ${$hashref}{$index} = \%newhash;
}

sub pop_hash {
   my $hashref = shift;
   my $index = "__push_hash_index";

   %{$hashref} = %{${$hashref}{$index}};
}

#--------------------------------------------------------------------------
# Here's the man page so far.
#
sub usage {
   my @cmd = split("/", $0);
   warn("Usage: $cmd[$#cmd] \[-s subnet-id\]\n");
}

1;
