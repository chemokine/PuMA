#!/usr/bin/perl
########################################################
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
# combine.pl                                            #
#########################################################

use strict;
use warnings;
use Getopt::Std;
use POSIX qw/ ceil floor /;
use vars qw/ $opt_d $opt_o $opt_r/;

#########################################################
# Start Variable declarations                           #
#########################################################

my ($rundir, $outfile);
my $i = 0;
my @dirnames;
my @catarray;
my @samplearray;
my %cathash;
my %samplehash;
my %oldhash;
my %newhash;
my $output_data;


#########################################################
# End Variable declarations                             #
#########################################################

#########################################################
# Start Main body of Program                            #
#########################################################

 &getopts('vi:d:o:r:');
 &var_check();

 print "\n".&ascii_logo()."";
 print "\n\033[31m\033[1m- Starting PuMA Pipeline Combine Tool -\033[0m\n";
 print "\n\tStarting to Build a Combined file from PuMA Pipeline Outputs.\n";

 open( OUTFILE1, ">", "$outfile.long.tsv")  or die "Can not open $outfile.long.tsv: $!";

 foreach my $rundir(@dirnames) {

	print "\t\tRunning convert process on PuMA Pipeline files: $rundir\n";

 	unless(-d "$rundir"){
        	print "\t\t\t Directory $rundir does not exist!\n";
        	exit 0;
 	}

 	unless(-e "$rundir/all_counts.tsv"){
 	       print "\t\t\t File $rundir/all_counts.tsv does not exist!\n";
 	       exit 0;
 	}
 	open( INFILE, "<", "$rundir/all_counts.tsv")  or die "Can not open $rundir/all_counts.tsv: $!";
 	while (<INFILE>){
		chomp($_);
	 	print OUTFILE1 "$_\n";

		my ($sample, $type, $catagory, $count) = split(/\t/, $_);
		#print "\t\t\tsample = $sample, type = $type, count = $count\n";

                if(defined($cathash{$catagory})){
		} else {
                        my %hash;
                        $hash{'catagory'} = $catagory;
                        $hash{'count'} = "\"$catagory\"";
                        $cathash{$catagory} = \%hash;
                        push @catarray, $catagory;
                }

                my %hash;
                $hash{'catagory'} = $catagory;
                $hash{'sample'} = $sample;
                $hash{'count'} = "$count";
                $samplehash{$catagory."-".$sample} = \%hash;
                push @samplearray, $sample;


	}

	close INFILE;

 }

 close OUTFILE1;

 my @unique = uniq( @samplearray );

 foreach my $sample(@unique) {
 	foreach my $catagory(@catarray) {
                if(defined($samplehash{$catagory."-".$sample})){
                        my $hash1 = $cathash{$catagory};
                        my $hash2 = $samplehash{$catagory."-".$sample};
			$hash1->{'count'} .= "\t".$hash2->{'count'}."";
		} else {
                        my $hash1 = $cathash{$catagory};
			$hash1->{'count'} .= "\t0";
                }

	}

 }


 open( OUTFILE2, ">", "$outfile.wide.tsv")  or die "Can not open $outfile.wide.tsv: $!";
 print OUTFILE2 "\"category\"\t".join("\t", @unique )."\n";
 foreach my $catagory(@catarray) {
        my $hash = $cathash{$catagory};
 	print OUTFILE2 "".$hash->{'count'}."\n";
 }
 close OUTFILE2;

 print "\tDone Building Combined file from PuMA Pipeline Outputs\n\n";
 print "\033[31m\033[1m- Finished PuMA Pipeline Combine Tool -\033[0m\n\n";


 exit 0;

#########################################################
# End Main body of Program                              #
#########################################################

sub uniq {
	my %seen;
	return grep { !$seen{$_}++ } @_;
}

#########################################################
# Start parse_into_array Sub                            #
#########################################################

sub parse_into_array {
        my $input = shift;
        my @temp_list;
        my @final_list;

        # put each semicolon separated entry in an array
        if ($input =~ /;/) {
                @temp_list = split/;/,$input;
        } else {
                push(@temp_list,$input);
        }

        # expand range entries
        foreach my $temp_element (@temp_list){
                if ($temp_element =~ /(.*?)\[(\d+?)-(\d+?)\](.*)/) {
                        my $start_text = $1;
                        my $low_num = $2;
                        my $high_num = $3;
                        my $end_text = $4;
                        if(! ($low_num < $high_num)){
                                croak("Error: invalid input range\n");
                        }
                        for my $this_num ($low_num..$high_num){
                                my $this_entry = $start_text . $this_num . $end_text;
                                push(@final_list,$this_entry);
                        }
                } else {
                        push(@final_list,$temp_element);
                }
        }

        return @final_list;
}

#########################################################
# End parse_into_array Sub                              #
#########################################################

sub ascii_logo {

        my $ascii_art = "";

        $ascii_art .= "\033[31m\033[1m";
        $ascii_art .= "\t██████╗             ███╗   ███╗    █████╗    \n";
        $ascii_art .= "\t██╔══██╗██║   ██║   ████╗ ████║   ██╔══██╗   \n";
        $ascii_art .= "\t██████╔╝██║   ██║   ██╔████╔██║   ███████║   \n";
        $ascii_art .= "\t██╔═══╝ ██║   ██║   ██║╚██╔╝██║   ██╔══██║   \n";
        $ascii_art .= "\t██║██╗  ╚██████╔╝██╗██║ ╚═╝ ██║██╗██║  ██║██╗\n";
        $ascii_art .= "\t╚═╝╚═╝   ╚═════╝ ╚═╝╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚═╝\n";
        $ascii_art .= "\033[0m";

        return $ascii_art;

}

 
#########################################################
# Start of Variable Check Subroutine "var_check"        #
# if we came from command line do we have information   #
# and is it the correct info.. if not go to the menu... #
# if we came from the web it should all check out...    #
#########################################################

sub var_check {

        if ($opt_d) {
                @dirnames = parse_into_array($opt_d);
                foreach my $thisdir (@dirnames){
                        croak("Error: file '$thisdir' does not exist\n") if (! -r $thisdir);
                }
        } else {
                &var_error();
        }
 	if (defined($opt_o)) {
   		$outfile = $opt_o;
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
  print "  combine.pl -d <puma run directories> -o <output file name> \n";
  print "\n\n\n";
  print "  -d   The Run Directories containing your PuMA Pipeline data.\n";
  print "\tFor Example:\n";
  print "\t  -d 'C1_data.fq'\n";
  print "\t  -d 'C[1-2]_data.fq'\n";
  print "\t  -d 'C[1-4]_data.fq;C[6-7]_data.fq'\n";
  print "\n";
  print "  -o   Output identifier\n";
  print "\tFor Example:\n";
  print "\t  -o 'all_samples'\n";
  print "\n\n\n";
  exit 0;

}

#########################################################
# End of Variable error Subroutine "var_error"          #
#########################################################

