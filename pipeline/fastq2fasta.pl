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
use vars qw/ $opt_f $opt_o $opt_l $opt_r/;

#########################################################
# Start Variable declarations                           #
#########################################################

my ($file, $outfile, $logfile);
my $i = 0;

#########################################################
# End Variable declarations                             #
#########################################################

#########################################################
# Start Main body of Program                            #
#########################################################

 &getopts('f:o:l:');
 &var_check();

 print "\t\tRunning convert process on FASTQ file: $file\n";
 print `echo "Running convert process on FASTQ file: $file" >> $logfile`;

 unless(-e "$file"){
        print "\t\t\t File $file does not exist!\n";
        exit 0;
 }

 open( INFILE, "<", $file)  or die "Can not open $file: $!";
 open( OUTFILE, ">", $outfile)  or die "Can not open $outfile: $!";

 while (<INFILE>){

	chomp($_);
	my $line0 = $_;
	chomp(my $line1 = <INFILE>);
	chomp(my $line2 = <INFILE>);
	chomp(my $line3 = <INFILE>);

	if ($line0 =~ m/^\@/){ 
		$line0 =~ s/^\@//g;
  		print OUTFILE ">$line0\n";
  		print OUTFILE "$line1\n";
		$i++;
	}
	else {
		print `echo "\n\n\tThe input file is not in FASTQ format">> $logfile`; 
		print `echo  "\tLine 1 = $line0\n" >> $logfile`;
		print `echo  "\tLine 2 = $line1\n" >> $logfile`;
		print `echo  "\tLine 3 = $line2\n" >> $logfile`;
		print `echo  "\tLine 4 = $line3\n" >> $logfile`;
		print `echo  "\n" >> $logfile`;
		exit 0;
	}

 }

 close INFILE;
 close OUTFILE;
 

#########################################################
# Start of Variable Check Subroutine "var_check"        #
# if we came from command line do we have information   #
# and is it the correct info.. if not go to the menu... #
# if we came from the web it should all check out...    #
#########################################################

sub var_check {

	if (defined($opt_f)) {
		$file = $opt_f;
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
  print "  fastq2fasta.pl -f <input fastq file> -o <outfile fasta name> -l <logfile>\n";
  print "\n\n\n";
  print "  -f   Input data file in FASTQ format.\n";
  print "\n";
  print "  -o   Outfile FASTA file name.\n";
  print "\n";
  print "  -l   The logfile name:\n";
  print "\n\n\n";
  exit 0;

}

#########################################################
# End of Variable error Subroutine "var_error"          #
#########################################################

