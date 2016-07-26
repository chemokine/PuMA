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
croak("Error: MEGAN stanza does not exist in conf file\n") if(($Conf->get('MEGAN','megan')) eq -1);
my $program = $Conf->get('MEGAN','megan');
my $program_options = $Conf->get('MEGAN','megan_options');
my $meganLicense = $Conf->get('MEGAN','meganLicense');
my $taxGIFile = $Conf->get('MEGAN','taxGIFile');
my $seedGIFile = $Conf->get('MEGAN','seedGIFile');
my $keggGIFile = $Conf->get('MEGAN','keggGIFile');
my $xvfbrun = $Conf->get('PuMA','xvfbrun');

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
  &megan_commands();
  $program_options .= " -g -L $meganLicense -c $run_id.MEGAN-Cmds.txt";
  $current_command = "$xvfbrun --auto-servernum --server-num=$$ $program $program_options";

  # Run Program:
  print `echo "command: $current_command" >> $logfile`;
  open($filehandle,"| $current_command >>$logfile") or die "can't open CMD: $!"; # open pipe with command
  close($filehandle);

  exit 0;

#########################################################
# End Main body of Program                              #
#########################################################

sub megan_commands() {
	my $megan_cmds = "";
	$megan_cmds .= "load taxGIFile='$taxGIFile';\n";
        $megan_cmds .= "load seedGIFile = '$seedGIFile';\n";
        $megan_cmds .= "load keggGIFile = '$keggGIFile';\n";
        $megan_cmds .= "import blastfile='$run_id.diamond.tsv' meganfile='megan_result.bin' maxmatches=20 minscore=50.0 toppercent=10.0 minsupport=1 mincomplexity=0.0 useSeed=true useKegg=true paired=false blastformat=BlastTAB MAPPING='Taxonomy:GI_MAP=true,SEED:GI_MAP=true,KEGG:GI_MAP=true';\n";
        $megan_cmds .= "collapse rank=Species;\n";
        $megan_cmds .= "update reprocess=false;\n";
        $megan_cmds .= "select nodes=leaves;\n";
        $megan_cmds .= "update reprocess=false;\n";
        $megan_cmds .= "export what=CSV format=taxonpath_count separator=tab file='taxonpath_count.txt';\n";
        $megan_cmds .= "update reprocess=false;\n";
        $megan_cmds .= "export what=CSV format=taxonpath_readname separator=tab file='taxonpath_readname.txt';\n";
        $megan_cmds .= "show window=seedViewer;\n";
        $megan_cmds .= "set context=seedViewer;\n";
        $megan_cmds .= "update reprocess=false;\n";
        $megan_cmds .= "uncollapse nodes=all;\n";
        $megan_cmds .= "update reprocess=false;\n";
        $megan_cmds .= "select nodes=leaves;\n";
        $megan_cmds .= "update reprocess=false;\n";
        $megan_cmds .= "export what=CSV format=seedpath_count separator=tab file='seedpath_count.txt';\n";
        $megan_cmds .= "update reprocess=false;\n";
        $megan_cmds .= "export what=CSV format=seedpath_readname separator=tab file='seedpath_readname.txt';\n";
        $megan_cmds .= "show window=keggViewer;\n";
        $megan_cmds .= "set context=keggViewer;\n";
        $megan_cmds .= "update reprocess=false;\n";
        $megan_cmds .= "uncollapse nodes=all;\n";
        $megan_cmds .= "update reprocess=false;\n";
        $megan_cmds .= "select nodes=leaves;\n";
        $megan_cmds .= "update reprocess=false;\n";
        $megan_cmds .= "export what=CSV format=keggpath_count separator=tab file='keggpath_count.txt';\n";
        $megan_cmds .= "update reprocess=false;\n";
        $megan_cmds .= "export what=CSV format=keggpath_readname separator=tab file='keggpath_readname.txt';\n";
        $megan_cmds .= "quit;\n";

	print `echo "$megan_cmds" > $run_id.MEGAN-Cmds.txt`;

}

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
  print "  run_megan.pl -f <inputfile> -l <logfile> -r <run_id> -c <run config file>\n";
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
