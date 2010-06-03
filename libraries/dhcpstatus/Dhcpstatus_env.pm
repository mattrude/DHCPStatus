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

package Dhcpstatus_env;

#
# This package keeps track of user options defined in
# $DHCPSTATUS/dhcpstatus.ini
#

sub new {
   my $env = {};
   shift;					# move past package name.
   my $dir = shift;				# the caller tells us where the
   my $ini_file = $dir."/dhcpstatus.ini";	# .ini file is located.

   open(INI, $ini_file);			# read the .ini file, and
   my @ini = <INI>;				# put the info into our env
   close(INI);					# object.
   chomp(@ini);

   my %ini;
   for (my $i = 0; $i <= $#ini; $i++) {
      next if (substr($ini[$i], 0, 1) eq "#");
      my $key;
      my $val;
      ($key, $val) = split(/=/, $ini[$i]);
      $key =~ tr/A-Z/a-z/;
      $ini{$key} = $val;
   }

   $env->{TITLE} = $ini{"title"};
   $env->{CONF_FILE} = $ini{"conf_file"};
   $env->{LEASES_FILE} = $ini{"leases_file"};
   $env->{SHOW_WHOLE_SUBNET} = $ini{"show_whole_subnet"};
   $env->{DIR} = $dir;
   $env->{SCREEN_WIDTH} = $ini{"screen_width"};

   bless($env);
   return($env);
}

sub get_screen_width {
   my $env = shift;
   my $width;
   eval q(use Term::ReadKey;);
   return if ($@);
   eval q($width = (GetTerminalSize())[0];);
   return if ($@);
   $env->{SCREEN_WIDTH} = $width;
}

sub title {
   my $env = shift;
   return($env->{TITLE});
}

sub conf_file {
   my $env = shift;
   return($env->{CONF_FILE});
}

sub leases_file {
   my $env = shift;
   return($env->{LEASES_FILE});
}

sub show_whole_subnet {
   my $env = shift;
   return($env->{SHOW_WHOLE_SUBNET});
}

sub dir {
   my $env = shift;
   return($env->{DIR});
}

sub screen_width {
   my $env = shift;
   return($env->{SCREEN_WIDTH});
}

1;
