########################################################
#  PUMA
#
#  Copyright 2016
#
#  Xiaoxi Dong
#  Christopher M. Sullivan
#  Andriy Morgun
#
#  College of Pharmacy,
#  Center for Genome Research and Biocomputing
#  Oregon State University
#  Corvallis, OR 97331
#
#  email: andriy.morgun@oregonstate.edu
#
# This program is not free software; you can not redistribute it and/or
# modify it at all.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#########################################################

#########################
# Configuration.pm	#
#########################

package Configuration;
use FindBin qw($Bin);
use lib "$Bin";
use lib "$Bin/..";
use pipeline::Tiny;

# Designed to read a .ini formatted configuration file.
# Example of .ini:

# [Section]
# name=value
# name=value
# name=value

# [Section2]
# name=value
# name=value
# etc..

# This module currently is basically just a wrapper for Config::Tiny.  The reason
# I built this wrapper was so that in the future if another Config module needed to be used,
# we can simply replace references to Config::Tiny here with the new module, and change the 
# syntax of how we obtain the values from the .ini formated config file.

sub new
{
	# allow for inheritance
	my ($class,%params) 		= @_;
	
	my $this            		= {};
	
	#$this->{config}			= Config::Tiny->new();
	#$this->{config}			= Config::Tiny->read($params{file});
        $this->{config}                 = Tiny->new();
        $this->{config}                 = Tiny->read($params{file});
	
	# allow for inheritance, if needed
	bless($this,$class);
	return $this;
} # end sub new


# $config->get('SECTION','variable');
sub get
{
	my ($this,$section,$key)	 	= @_;
	
	if(exists $this->{config}->{$section}->{$key} ) { return $this->{config}->{$section}->{$key}; }
	return -1;
}



###########################################################################
# 			Perldoc begin
###########################################################################

=head1 Name

Config.pm - Used to extract values from a .ini formatted configuration file.

=head1 Synopsis

# configuration file that is .ini formatted like this:

# [PUMA]
# CUTADAPT=cutadapt

# perl code to access .ini formatting
require Config;

my $config	= new Config(file=>'config.conf');
my $host	= $config->get("CUTADAPT","cutadapt"); # get(section,variable)

=head1 Description

This is a simple module to deal with simple configuration files that are .ini formatted.
Currently, this module is a wrapper to Config::Tiny (cpan).  I wrapped the module so that in
the future if there is ever a need to change configuration modules (for something more complicated, 
or just different), the code will only have to be changed in one place instead of everywhere 
information from the configuration file is used.

=head1 AUTHOR

        OSU CGRB


=head1 COPYRIGHT

Copyright 2001-2016. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this pipeline.

=cut


1;

