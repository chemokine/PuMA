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
# fastq2fasta                                           #
#########################################################

use strict;
use warnings;
use Getopt::Std;
use POSIX qw/ ceil floor /;
use vars qw/ $opt_r $opt_o $opt_l $opt_r/;

#########################################################
# Start Variable declarations                           #
#########################################################

my ($rundir, $outfile, $logfile);
my $i = 0;

#########################################################
# End Variable declarations                             #
#########################################################

#########################################################
# Start Main body of Program                            #
#########################################################

 &getopts('r:o:l:');
 &var_check();

 print "\t\tRunning convert process on PuMA Pipeline files: $rundir\n";
 print `echo "Running convert process on PuMA Pipeline files: $rundir" >> $logfile`;

 my @run_ids = (split /\./, $rundir);
 my $dirname = pop @run_ids;
 my $processid = pop @run_ids;
 my $run_id = join( '.', @run_ids );

 open( OUTFILE, ">", $outfile)  or die "Can not open $outfile: $!";

 unless(-d "$rundir"){
        print "\t\t\t Directory $rundir does not exist!\n";
        exit 0;
 }

 unless(-e "$rundir/keggpath_count.txt"){
        print "\t\t\t File $rundir/keggpath_count.txt does not exist!\n";
        exit 0;
 }
 open( INFILE1, "<", "$rundir/keggpath_count.txt")  or die "Can not open $rundir/keggpath_count.txt: $!";
 while (<INFILE1>){
	chomp($_);
	my($catagory, $count) = split(/\t/,$_);

	if ($catagory =~ m/KEGG/){
		$catagory =~ s/\"//g;
 		print OUTFILE "$run_id\tkegg\t$catagory\t$count\n";
	}
	else {
		print "Unknown Catagory to process!\n";
	}

 }

 unless(-e "$rundir/seedpath_count.txt"){
        print "\t\t\t File $rundir/seedpath_count.txt does not exist!\n";
        exit 0;
 }
 open( INFILE2, "<", "$rundir/seedpath_count.txt")  or die "Can not open $rundir/seedpath_count.txt: $!";
 while (<INFILE2>){
	chomp($_);
	my($catagory, $count) = split(/\t/,$_);

	if ($catagory =~ m/SEED/){
		$catagory =~ s/\"//g;
 		print OUTFILE "$run_id\tseed\t$catagory\t$count\n";
	}
	else {
		print "Unknown Catagory to process!\n";
	}

 }


 unless(-e "$rundir/taxonpath_count.txt"){
        print "\t\t\t File $rundir/taxonpath_count.txt does not exist!\n";
        exit 0;
 }
 open( INFILE3, "<", "$rundir/taxonpath_count.txt")  or die "Can not open $rundir/taxonpath_count.txt: $!";
 while (<INFILE3>){
	chomp($_);
	my($catagory, $count) = split(/\t/,$_);

	if ($catagory =~ m/root/){
		$catagory =~ s/\"//g;
 		print OUTFILE "$run_id\ttaxon\t$catagory\t$count\n";
	}
	else {
		print "Unknown Catagory to process!\n";
	}

 }


 close INFILE1;
 close INFILE2;
 close INFILE3;
 close OUTFILE;

 exit 0;
 
#########################################################
# Start of Variable Check Subroutine "var_check"        #
# if we came from command line do we have information   #
# and is it the correct info.. if not go to the menu... #
# if we came from the web it should all check out...    #
#########################################################

sub var_check {

	if (defined($opt_r)) {
		$rundir = $opt_r;
	} else {
   		&var_error();
  	}

 	if (defined($opt_o)) {
   		$outfile = $opt_o;
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
# End of Variable Check Subroutine "var_check"          #
#########################################################

#########################################################
# Start of Variable error Subroutine "var_error"        #
#########################################################
sub var_error {

  print "\n\n";
  print "  You did not provide all the correct command line arguments\n\n";
  print "  Usage:\n";
  print "  convert_output.pl -r <run directory> -o <output file name> -l <logfile>\n";
  print "\n\n\n";
  print "  -r   PuMA Pipeline Run directory.\n";
  print "\n";
  print "  -o   Output file name.\n";
  print "\n";
  print "  -l   The logfile name:\n";
  print "\n\n\n";
  exit 0;

}

#########################################################
# End of Variable error Subroutine "var_error"          #
#########################################################

