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
# Puma Pipeline (cutadapt)                               #
#########################################################

use strict "vars";
use strict "subs";
use Carp;
use Cwd;
use Getopt::Std;
use FindBin qw($Bin);
use lib "$Bin";
use File::Copy;
use File::Basename;
use Configuration;
use vars qw/ $opt_f $opt_a $opt_l $opt_c $opt_r/;


#########################################################
# Start Variable declarations                           #
#########################################################

my ($file, $conf_file, $run_id, $logfile, $current_command, $filehandle, $adaptors);

&getopts('f:a:l:c:r:');
&var_check();

# get settings from conf file
my $Conf = new Configuration(file => $conf_file);
croak("Error: PuMA stanza does not exist in conf file\n") if(($Conf->get('Cutadapt','cutadapt')) eq -1);
my $program = $Conf->get('Cutadapt','cutadapt');
my $program_options = $Conf->get('Cutadapt','cutadapt_options');
my $adaptors_list = "";

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

  unless(-e "$adaptors"){
  	print "\t\t\t File $adaptors does not exist!\n";
        exit 0;
  }

  open DATA, "< $adaptors";
  my @data = <DATA>;
  close DATA;

  foreach my $line(@data) {
  	chomp $line;
        if ($line =~ m/[AGTC]/){
        	$adaptors_list .= "-a $line ";
        }
  }

  if ($adaptors_list) {
  	# Build Command:
        $program_options .= " $adaptors_list -o $run_id.cutadapt.out $file";
  	$current_command = "$program $program_options";

  	# Run Program:
  	print `echo "command: $current_command" >> $logfile`;
  	open($filehandle,"| $current_command >>$logfile") or die "can't open CMD: $!"; # open pipe with command
  	close($filehandle);
  }
  else {
  	print "\t\t Can not get file list of adaptors within adapter file\n";
        print `echo "Can not get file list of adaptors within adapter file\n" >> $logfile`;
        exit 0;
  }

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
                $conf_file = "$Bin/conf/example.conf";
        }
        if ($opt_r) {
                $run_id = $opt_r;
        } else {
		&var_error();
        }
        if ($opt_a) {
                $adaptors = $opt_a;
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
  print "  Runs the Cutadapt and processes the input file given by the -f option and processess it through cutadapt\n";
  print "  Usage:\n";
  print "  run_cutadapt.pl -f <inputfile> -a <adaptors> -l <logfile> -r <run_id> -c <run config file>\n";
  print "\n\n\n";
  print "  -f   The input fastq file:\n";
  print "\n";
  print "  -a   Input file of adaptor sequences (one per line).\n";
  print "\n";
  print "  -l   The logfile name:\n";
  print "\n";
  print "  -r   The RunID for the pipeline:\n";
  print "\n";
  print "  -c   The run configuration file (default = $Bin/conf/example.conf):\n";
  print "\n\n\n";
  exit(0);
}

#########################################################
# End of Varriable error Subroutine "var_error"         #
#########################################################
