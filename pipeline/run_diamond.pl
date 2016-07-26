#!/usr/bin/perl
#########################################################
#  PuMA
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

#########################################################
# Puma Pipeline (diamond)                               #
#########################################################

use strict "vars";
use strict "subs";
use Carp;
use Cwd;
use Getopt::Std;
use FindBin qw($Bin);
use lib "$Bin/..";
use File::Copy;
use File::Basename;
use pipeline::Configuration;
use vars qw/ $opt_f $opt_l $opt_c $opt_r/;

#########################################################
# Start Variable declarations                           #
#########################################################

my ($file, $conf_file, $run_id, $logfile, $current_command, $filehandle);

&getopts('f:l:c:r:');
&var_check();

# get settings from conf file
my $Conf = new Configuration(file => $conf_file);
croak("Error: PuMA stanza does not exist in conf file\n") if(($Conf->get('Diamond','diamond')) eq -1);
my $program = $Conf->get('Diamond','diamond');
my $program_options = $Conf->get('Diamond','diamond_options');
my $diadb = $Conf->get('Diamond','diamond_db');

#########################################################
# End Variable declarations                             #
#########################################################

#########################################################
# Start Main body of Program                            #
#########################################################

  $filehandle = "FILE";

  print "\t\tRunning $program on $file\n";
  print `echo "Running $program on $file" >> $logfile`;

  unless(-e "$file"){
        print "\t\t\t File $file does not exist!\n";
        exit 0;
  }

  # Build Command:
  $program_options .= " blastx -q $file -d $diadb -a $run_id.diamond";
  $current_command = "$program $program_options; $program view -a $run_id.diamond.daa -o $run_id.diamond.tsv";

  # Run Program:
  print `echo "command: $current_command" >> $logfile`;
  open($filehandle,"| $current_command >>$logfile") or die "can't open CMD: $!"; # open pipe with command
  close($filehandle);

  exit 0;

#########################################################
# End Main body of Program                              #
#########################################################

########################################################
# Start of Varriable Check Subroutine "var_check"       #
# if we came from command line do we have information   #
# and is it the correct info.. if not go to the menu... #
# if we came from the web it should all check out...    #
#########################################################

sub var_check(){
	if(!defined($opt_f)){
		&var_error();
	}else{
		if(!($opt_f =~ m/^\s+$/)){
			$file = $opt_f;
		}else{
			&var_error();
		}
	}
        if ($opt_c) {
                $conf_file = $opt_c;
        } else {
		&var_error();
        }
        if ($opt_r) {
                $run_id = $opt_r;
        } else {
		&var_error();
        }
	if(defined($opt_l)){
		$logfile = $opt_l;
        } else {
		&var_error();
        }
}

#########################################################
# End of Varriable Check Subroutine "var_check"         #
#########################################################

#########################################################
# Start of Varriable error Subroutine "var_error"       #
#########################################################

sub var_error(){
  print "\n  Description:\n";
  print "  run_diamond.pl processes the input file given by the -f option and processess it through diamond\n";
  print "  Usage:\n";
  print "  run_diamond.pl -f <inputfile> -o <outputfile> -x <diamond db> -r <run_id> -c <run config file>\n";
  print "\n\n\n";
  print "  -f   The input fasta file:\n";
  print "\n";
  print "  -l   The logfile name:\n";
  print "\n";
  print "  -r   The RunID for the pipeline:\n";
  print "\n";
  print "  -c   The run configuration file (default = <pipelinedir>/conf/example.conf):\n";
  print "\n\n\n";
  exit(0);
}

#########################################################
# End of Varriable error Subroutine "var_error"         #
#########################################################
