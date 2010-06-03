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
# Convert DHCP lease date & time parameters (eg. 2000/07/02, 17:11:30) to
# epoch time.
#
sub lease_time {
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

#--------------------------------------------------------------------------
# Take an array of symbols that have been extracted from the dhcpd.leases
# file, and return a hash.  Each element of the hash has, as its key, an
# IP address that is still active (not yet ended and not abandoned).  The
# values of all the hash elements are set to 1 (for no particular reason, I
# just wanted them to be set to something).
#
sub get_active_lease_ips {
   my %lease_ips;
LEASE:
   while (@_) {
      if ($_[0] ne "lease") {		# ignore anything that isn't a lease.
         while (shift ne "}") {}
         next LEASE;
      }
      shift;			# move past the "lease" keyword.
      my $ip = shift;		# get the ip address of the lease.
      shift;			# move past the opening brace.
LEASE_PARM:
      while ($_[0] ne "}") {
         if (($_[0] eq "ends") && ($_[1] ne "never")) {
            if (&lease_time($_[2], $_[3]) < time()) {	# if the lease has
               while (shift ne "}") {}			# ended, we're not
               next LEASE;				# interested.
            }
         }
         if (($_[0] eq "abandoned")		# ditto for abandoned leases.
          || ($_[0] eq "deleted")		# the man page is a bit vague
          || ($_[0] eq "rubout")) {		# about whether these are
            while (shift ne "}") {}		# keywords.
            next LEASE;
         }
         if ($_[0] eq "on") {			# ignore "on events { ... }"
            while (shift ne "}") {}
            next LEASE_PARM;
         }
         while (@_ && shift ne ";") {}		# go to next lease parm.
      }
      $lease_ips{$ip} = 1;	# if we got this far, we got an active lease.
      shift;			# move past closing brace.
   }
   return(%lease_ips);
}

#--------------------------------------------------------------------------
# This subroutine is invoked when we hit a "shared-network" keyword.  Here,
# we are passed a new %parms hash by value from the caller, so we can
# modify it as we come across new options/parameters, and the changes we
# make to it will disappear when we reach the end of the shared network.
#
sub get_shared_network_subnets {
   my $symref = shift;
   my %parms = @_;

   splice(@$symref, 0, 3);	# move past the shared-network <id> { symbols.
   my @subnet;			# array describing subnets in this shared net.
   my @pool;			# array describing pools in this shared net.
   my $group_count = 0;
   while ($$symref[0] ne "}") {
      if ($$symref[0] eq "subnet") {			# found one.
         push(@subnet, &get_subnet($symref, %parms));
         $parms{"comment"} = "";		# so old comments don't
         next;					# apply to future subnets.
      }
      if ($$symref[0] eq "pool") {		# keep a list of pools to
         push(@pool, &get_pool($symref));	# search for ranges in later.
         next;
      }
      if (substr($$symref[0], 0, 1) eq "\$") {		# found a comment,
         $parms{"comment"} = substr($$symref[0], 1);	# save it as a parm.
         shift(@$symref);
         next;
      }
      if ($$symref[0] eq "group") {		# found a group, need to set up
         &push_hash(\%parms);			# a new parms environment.
         splice(@$symref, 0, 2);		# move past "group {".
         $group_count++;			# count how many groups deep we
         next;					# are.
      }
      if ($$symref[0] eq "}") {			# assume this brace is the end
         last if ($group_count == 0);		# of a group definition.
         &pop_hash(\%parms);			# restore parms environment.
         shift(@$symref);			# move past the brace.
         $group_count--;			# one less group to worry about.
         next;
      }
      my ($key, $value) = &get_value($symref);		# assume we're looking
      $parms{$key} = $value;				# at a parm or option.
      next;
   }
   shift(@$symref);		# move past the last brace.
   for (my $s = 0; $s <= $#subnet; $s++) {		# for each subnet,
      my $ip_min = $subnet[$s]->ip_min;			# check to see if any
      my $ip_max = $subnet[$s]->ip_max;			# of the pools we found
      for (my $p = 0; $p <= $#pool; $p++) {		# contain ranges that
         my $ranges = $pool[$p]->ranges_defined;	# fall within that
         for (my $r = 0; $r <= $ranges; $r++) {		# subnet, and update
            my @range = $pool[$p]->get_range($r);	# the subnet
            if ((&ip2num($range[0]) >= &ip2num($ip_min))	# accordingly.
                 && (&ip2num($range[1]) <= &ip2num($ip_max))) {
               for (my $num = &ip2num($range[0]);
                  $num <= &ip2num($range[1]);
                  $num++) {
                  $subnet[$s]->ips(&num2ip($num));
               }
            }
         }
      }
   }
   return(@subnet);
}

#--------------------------------------------------------------------------
# This is the starting point for parsing the array of symbols that was
# extracted from the dhcpd.conf file.  An array of subnets is created,
# and added to when we come across a "subnet" keyword.  When we hit
# a "shared-network", control is passed to &get_shared_network_subnets
# so that a new parameter space can be maintained;  that subroutine will
# return an array of subnets found in the shared network.  Anything we can't
# recognise, we assume is an option or a parameter.
#
sub parse_conf_sym {
   my $symref = shift;
   my %parms = @_;

   my @subnet;
   my $group_count = 0;

   while (@$symref) {
      if (substr($$symref[0], 0, 1) eq "\$") {		# found a comment, save
         $parms{"comment"} = substr($$symref[0], 1);	# it to describe our
         shift(@$symref);				# next subnet.
         next;
      }
      if ($$symref[0] eq "subnet") {			# found a subnet, so
         push(@subnet, &get_subnet($symref, %parms));	# process it and add it
         $parms{"comment"} = "";			# to the array.
         next;
      }
      if ($$symref[0] eq "shared-network") {		# found a shared net,
         push(@subnet, &get_shared_network_subnets($symref, %parms));
         $parms{"comment"} = "";			# needs its own parm
         next;						# space.
      }
      if ($$symref[0] eq "group") {             # found a group, need to set up
         &push_hash(\%parms);                   # a new parms environment.
         splice(@$symref, 0, 2);                # move past "group {".
         $group_count++;                        # count how many groups deep we
         next;                                  # are.
      }
      if ($$symref[0] eq "}") {                 # assume this brace is the end
         last if ($group_count == 0);           # of a group definition.
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
      my ($key, $value) = &get_value($symref);		# anything else must
      $parms{$key} = $value;				# be a parm or option.
      next;
   }
   return(@subnet);
}

#--------------------------------------------------------------------------
# Correlate the information that we know about subnets and leases, and return
# the info in a Display object.
#
sub correlate {
   my $title = shift;
   my @subnet = @{$_[0]};
   my %lease = %{$_[1]};

   my $display = Display->new;

   $display->title($title);
   $display->headings("Location", "Subnet", "Netmask", "IP range", "Router",
                      "IPs defined", "IPs used", "IPs free");

#
# A row of info for each subnet.
#
   foreach my $subnet (@subnet) {
      my $comment = $subnet->comment;

      my $subnet_id = Formatted_text->new;	# the subnet_id is formatted
      $subnet_id->text($subnet->subnet_id);	# to enable linking to a
      $subnet_id->href(".");			# program that can go into
      $subnet_id->href_parm("subnet", $subnet->subnet_id);	# more detail
						# about the subnet.

      my $netmask = $subnet->netmask;
      my $router = $subnet->router;
      my $ips_defined = $subnet->ips_defined;
      my $ip_min = $subnet->ip_min;
      my $ip_max = $subnet->ip_max;
      my $used_ips = 0;
      my $free_ips = 0;
      my $num_min = &ip2num($ip_min);
      my $num_max = &ip2num($ip_max);
      for (my $num = $num_min; $num <= $num_max; $num++) {
         my $ip = &num2ip($num);		# check each ip in the subnet
         if (defined($lease{$ip})) {		# to see if its defined, used,
            $used_ips++;			# free, etc. and keep running
         }					# totals of each.
         else {
            if ($subnet->ip_defined($ip)) {
               $free_ips++;
            }
         }
      }
      $display->row($comment,
                    $subnet_id,
                    $netmask,
                    "$ip_min - $ip_max",
                    $router,
                    $ips_defined,
                    $used_ips,
                    $free_ips
                   );
   }

   return($display)
}

1;
