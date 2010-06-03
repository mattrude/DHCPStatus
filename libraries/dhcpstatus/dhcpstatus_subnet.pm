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

#--------------------------------------------------------------------------
# The subnet that we're going to report on is passed to us through the
# QUERY_STRING parm by the CGI GET method.  It should look like
# "subnet=192.28.150.0".
#
sub get_subnet_id_parm {
   my $subnet_id;
   if (defined($ENV{"QUERY_STRING"})) {
      $subnet_id = (split(/=/, $ENV{"QUERY_STRING"}))[1];
      return($subnet_id);
   }
   else {
      return("");
   }
}

#--------------------------------------------------------------------------
# Pass through the list of symbols extracted from the dhcpd.conf file looking
# for the subnet we're interested in.  When we find it, pass the shortened
# array to &get_subnet, which extracts all the info about the subnet and
# returns it as a Subnet object.  This subroutine calls itself when it
# comes across a shared network.  This is done as a simple way of keeping
# parameter & option scoping consistent.
#
# Since I added support for pool statements, this subroutine has grown
# beyond the point of being easily maintainable, so it needs re-writing.
#
sub get_one_subnet {
   my $subnet_id = shift;	# the subnet we're looking for.
   my $shared_network = shift;	# are we inside a shared network ?
   my $symref = shift;		# ref to the symbols array.
   my %parms = @_;		# everything else is our parameter environment.

   my @pool;			# keep track of any pools we come across.
   my $subnet;
   my $group_count = 0;		# count the group statements.

   while (@$symref) {
      if (substr($$symref[0], 0, 1) eq "\$") {		# comment describing
         $parms{"comment"} = substr($$symref[0], 1);	# the next subnet.
         shift(@$symref);
         next;
      }
      if ($$symref[0] eq "subnet") {			# found a subnet,
         if ($$symref[1] eq $subnet_id) {		# is it ours ?
            $subnet = &get_subnet($symref, %parms);	# yes - process it.
            if (! $shared_network) {
               return($subnet);
            }
            next;
         }
         &ignore_statement($symref);	# ignore this subnet 'coz its not ours.
         $parms{"comment"} = "";	# the last subnet comment is no
         next;				# longer valid.
      }
      if ($$symref[0] eq "pool") {	# if we're inside a shared-network
         if ($shared_network) {		# statement, we want to keep track
            push(@pool, &get_pool($symref));	# of pools so that we can
            next;			# reconcile ranges in pools to subnets
         }				# later on.
         else {
            &ignore_statement($symref);
         }
      }
      if ($$symref[0] eq "shared-network") {		# call this subroutine
         splice(@$symref, 0, 3);			# recusively to handle
							# shared networks.
         my $subnet = &get_one_subnet($subnet_id, 1, $symref, %parms);
         if ($subnet) {				# if we've just returned from
            return($subnet);			# a shared network, and our
         }					# subnet was in it, we can
						# go home.
         $parms{"comment"} = "";
         next;
      }
      if ($$symref[0] eq "group") {             # found a group, need to set up
         &push_hash(\%parms);                   # a new parms environment.
         splice(@$symref, 0, 2);                # move past "group {".
         $group_count++;                        # count how many groups deep we
         next;                                  # are.
      }
      if (($$symref[0] eq "}")			# assume this brace is the end
             && $group_count) { 		# of a group definition.
         &pop_hash(\%parms);                    # restore parms environment.
         shift(@$symref);                       # move past the brace.
         $group_count--;                        # one less group to worry about.
         next;
      }
      if (($$symref[0] eq "host")		# all this stuff is ignored
       || ($$symref[0] eq "if")			# in this version.
       || ($$symref[0] eq "else")
       || ($$symref[0] eq "elsif")
       || ($$symref[0] eq "class")
       || ($$symref[0] eq "subclass")
       || ($$symref[0] eq "define")) {
         &ignore_statement($symref);
         next;
      }
      if ($$symref[0] eq "}") {		# reconcile any ranges in pools into
         shift(@$symref);		# their corresponding subnets.  this
         if ($subnet) {			# code is almost identical to some
            my $ip_min = $subnet->ip_min;	# code in dhcpstatus.cgi, and
            my $ip_max = $subnet->ip_max;	# should be put into a
            for (my $p = 0; $p <= $#pool; $p++) {	# subroutine one day.
               my $ranges = $pool[$p]->ranges_defined;
               for (my $r = 0; $r <= $ranges; $r++) {
                  my @range = $pool[$p]->get_range($r);
                  if ((&ip2num($range[0]) >= &ip2num($ip_min))
                       && (&ip2num($range[1]) <= &ip2num($ip_max))) {
                     for (my $num = &ip2num($range[0]);
                          $num <= &ip2num($range[1]);
                          $num++) {
                        $subnet->ips(&num2ip($num));
                     }
                  }
               }
            }
            return($subnet);	# this is the exit point if we're scanning a
         }			# shared network.  have to clean this
         else {			# spaghetti code up one day.
            return(0);
         }
      }
      my ($key, $value) = &get_value($symref);		# anything else must be
      $parms{$key} = $value;				# a parameter or option.
      next;
   }
}

#--------------------------------------------------------------------------
# The first two parameters to this subroutine are the start and finish IP
# addresses of a range that we are looking for lease information on.  The
# rest is the symbols extracted from the dhcpd.leases file.
# The subroutine passes through the lease symbols, looking for leases that
# are within the IP range specified, and are still active.  Info on leases
# that satisfy these requirements are stored in a hash of Lease objects,
# which is returned to the caller.
#
sub get_active_leases {
   use dhcpstatus::Lease;
   my $ip_min = shift;
   my $ip_max = shift;

   my $num_min = &ip2num($ip_min);	# numbers are easier to do arithmetic on
   my $num_max = &ip2num($ip_max);	# than IP addresses.
   my %lease;
LEASE:
   while (@_) {
      if ($_[0] ne "lease") {		# ignore anything that isn't a lease.
         while (shift ne "}") {}
         next LEASE;
      }
      shift;					# keyword "lease".
      my $ip = shift;				# IP addr of this lease.
      my $num = &ip2num($ip);			# if its not in the range,
      if ($num < $num_min || $num > $num_max) {
         while (shift ne "}") {}		# bypass it.
         next LEASE;
      }
      my $lease = Lease->new;			# got a lease in the range.
      shift;					# move past opening brace.
LEASE_PARM:
      while ($_[0] ne "}") {
         if ($_[0] eq "starts") {
            $lease->starts($_[2], $_[3]);
            while (shift ne ";") {}
            next LEASE_PARM;
         }
         if (($_[0] eq "ends") && ($_[1] ne "never")) {
            $lease->ends($_[2], $_[3]);
            if ($lease->ended) {		# if its an expired lease, we're
               while (shift ne "}") {}		# not interested in it.
               next LEASE;
            }
            while (shift ne ";") {}
            next LEASE_PARM;
         }
         if ($_[0] eq "hardware") {
            $lease->ethernet($_[2]);
            while (shift ne ";") {}
            next LEASE_PARM;
         }
         if ($_[0] eq "client-hostname") {
            $lease->wins($_[1]);
            while (shift ne ";") {}
            next LEASE_PARM;
         }
         if ($_[0] eq "hostname") {
            $lease->dns($_[1]);
            while (shift ne ";") {}
            next LEASE_PARM;
         }
         if (($_[0] eq "abandoned")		# ignore abandoned leases.
          || ($_[0] eq "deleted")		# and anything with these
          || ($_[0] eq "rubout")) {		# keywords, just in case.
            while (shift ne "}") {}
            next LEASE;
         }
         if ($_[0] eq "on") {			# ignore "on events { ...}".
            while (shift ne "}") {}
            next LEASE_PARM;
         }
         while (shift ne ";") {}		# ignore anything else we
      }						# don't understand/care about.
      $lease{$ip} = $lease;		# if we got this far, its a valid lease,
					# so add it to the hash.
      shift;				# move past lease's closing brace.
   }
   return(%lease);
}

#--------------------------------------------------------------------------
# Take an epoch time value, and return it formatted the same way as in the
# dhcpd.conf file.
#
sub ftime {
   my $time = shift;

   my ($ss, $ii, $hh, $dd, $mm, $yyyy, $wday, $yday, $isdst);
   ($ss, $ii, $hh, $dd, $mm, $yyyy, $wday, $yday, $isdst) = localtime($time);

   $mm++;				# coz months come out 0..11, not 1..12.
   $yyyy += 1900 if ($yyyy < 1900);	# apparently, this isn't a Y2K bug in
					# Perl, its a "feature" :-)

   my $ftime = sprintf("%02d/%02d/%04d %02d:%02d:%02d",
                       $dd, $mm, $yyyy, $hh, $ii, $ss);
   return($ftime);
}

#--------------------------------------------------------------------------
# Correlate the information that we know about subnets and leases, and return
# the info in a Display object.
#
sub correlate_subnet {
   my $title = shift;
   my $subnet = shift;
   my %lease = %{$_[0]};
   shift;
   my $show_whole_subnet = shift;

   my $display = Display->new;

   $display->title($title);

   $display->parm("Subnet", $subnet->subnet_id);
   $display->parm("Netmask", $subnet->netmask);
   $display->parm("Broadcast", $subnet->broadcast);
   $display->parm("Router", $subnet->router);
   $display->parm("DNS servers", $subnet->dns_server);
   $display->parm("WINS servers", $subnet->wins_server);
   $display->parm("IP range", $subnet->ip_min." - ".$subnet->ip_max);

   $display->headings("IP address", "Lease status", "Lease start", "Lease end",
                      "Mac address", "DNS name", "WINS name");
   $display->widths(15, 6, 10, 10, 9, 14, 9);

#
# A row of info for each IP.
#

   my $break = 1;
IP:for (my $num = &ip2num($subnet->ip_min);
           $num <= &ip2num($subnet->ip_max);
           $num++ ) {
      my $ip = &num2ip($num);
      my @row;
      if (defined($lease{$ip})) {
         if ($lease{$ip}->active) {
            my $ends = $lease{$ip}->ends;
            if ($ends ne "Never") {
               $ends = &ftime($ends);
            }
            @row = ($ip, "Active", &ftime($lease{$ip}->starts), $ends,
                    $lease{$ip}->ethernet, $lease{$ip}->dns, $lease{$ip}->wins);
         }
         $break = 1;
      }
      else {
         if ($subnet->ip_defined($ip)) {
            my $lease_status = Formatted_text->new;
            $lease_status->text("Free");
            $lease_status->bold(1);
            @row = ($ip, $lease_status, "", "", "", "", "");
            $break = 1;
         }
         else {
            if ($show_whole_subnet) {
               @row = ($ip, "", "", "", "", "", "");
            }
            else {
               if ($break) {
                  $display->row();
                  $break = 0;
               }
               next IP;
            }
         }
      }
      $display->row(@row);
   }

   return $display;
}

1;
