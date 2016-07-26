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
# Puma Pipeline (main) 					#
#########################################################

use strict "vars";
use strict "subs";
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use lib "$Bin/scripts";
use Carp;
use Cwd;
use Cwd qw(realpath);
use Getopt::Std;
use File::Copy;
use File::Basename;
use pipeline::Configuration;
use vars qw/ $opt_f $opt_a $opt_r $opt_d $opt_c/;

#########################################################
# Start Variable declarations                           #
#########################################################

my ($run_id, $comments, $adaptors, $rerundir, $file, $cmd, $conf_file, $bt2db, $realfile);
my $done_cutadapt = "No";
my $done_bowtie2 = "No";
my $done_fastq2fasta = "No";
my $done_diamond = "No";
my $done_MEGAN = "No";
my $done_Convert = "No";
my $done_Clean = "No";
my $logfile = "run_info.log";
my $rundir;
my $debug = 0;
my $workingdir = Cwd::getcwd();
my $files;
my $current_command;
my $filehandle;
my $rerundir_full;
my $current_process;
my $processes;

# arrays for parallel processing
my @filenames;
my @comments;

&getopts('vi:df:a:r:m:c:');
&var_check();

#########################################################
# End Variable declarations                             #
#########################################################

#########################################################
# Check for rerun folder option                         #
#########################################################
if($rerundir) {
	$rerundir_full = basename($rerundir);
	if (!-d "$rerundir_full") {
		print "\n\tCould not run folder $rerundir to restart data processing.\n\n";
		exit 0;
	}
	
        unless(-e "$rerundir_full/$logfile"){
                print "\n\t Log File $rerundir/$logfile does not exist!\n";
		exit 0;
        }

	print "\n\tReading Log Data for Run Configuration\n";
	print `echo "Reading Log Data for Run Configuration" >> $rerundir_full/$logfile`;
        open($filehandle,"$rerundir_full/$logfile") or die "can't open CMD: $!"; # open pipe with command

	while (my $line = <$filehandle>) {
		chomp $line;
		if ($line =~ /files=/) {
			$line =~ s/files=//g;
			@filenames = $line;
		}
		if ($line =~ /adaptors=/) {
			$adaptors = $line;
			$adaptors =~ s/adaptors=//g;
		}
		if ($line =~ /conf_file=/) {
			$conf_file = $line;
			$conf_file =~ s/conf_file=//g;
		}
		if ($line =~ /debug=/) {
			$debug = $line;
			$debug =~ s/debug=//g;
		}
		if ($line =~ /====> Done with cutadapt <====/) {
			$done_cutadapt = "Yes";
		}
		if ($line =~ /====> Done with bowtie2 <====/) {
			$done_bowtie2 = "Yes";
		}
		if ($line =~ /====> Done with fastq2fasta <====/) {
			$done_fastq2fasta = "Yes";
		}
		if ($line =~ /====> Done with diamond <====/) {
			$done_diamond = "Yes";
		}
		if ($line =~ /====> Done with MEGAN <====/) {
			$done_MEGAN = "Yes";
		}
		if ($line =~ /====> Done with Convert <====/) {
			$done_Convert = "Yes";
		}
		if ($line =~ /====> Done with Clean <====/) {
			$done_Clean = "Yes";
		}
	}


}



#########################################################
# End for rerun folder option                           #
#########################################################

#########################################################
# Start of Conf File settings 				#
#########################################################

$conf_file = realpath($conf_file);
$adaptors = realpath($adaptors);
my $Conf = new Configuration(file => $conf_file);
croak("Error: PuMA stanza does not exist in conf file\n") if(($Conf->get('PuMA','mkdir')) eq -1);
croak("Error: There is no bowtie2 path in the conf file\n") if(($Conf->get('Bowtie2','bowtie2')) eq "");
croak("Error: There is no bowtie2 DB path in the conf file\n") if(($Conf->get('Bowtie2','bowtie2_db')) eq "");
croak("Error: There is no cutadapt path in the conf file\n") if(($Conf->get('Cutadapt','cutadapt')) eq "");
croak("Error: There is no diamond path in the conf file\n") if(($Conf->get('Diamond','diamond')) eq "");
croak("Error: There is no diamond DB path in the conf file\n") if(($Conf->get('Diamond','diamond_db')) eq "");
croak("Error: There is no megan path in the conf file\n") if(($Conf->get('MEGAN','megan')) eq "");
croak("Error: There is no megan License path in the conf file\n") if(($Conf->get('MEGAN','meganLicense')) eq "");
croak("Error: There is no megan taxGIFile DB path in the conf file\n") if(($Conf->get('MEGAN','taxGIFile')) eq "");
croak("Error: There is no meagan seedGIFile DB path in the conf file\n") if(($Conf->get('MEGAN','seedGIFile')) eq "");
croak("Error: There is no megan keggGIFile DB path in the conf file\n") if(($Conf->get('MEGAN','keggGIFile')) eq "");
my $memory_usage = $Conf->get('PuMA','memory_usage'); 
my $mkdir = $Conf->get('PuMA','mkdir');
my $cat = $Conf->get('PuMA','cat');
my $cp = $Conf->get('PuMA','cp');
my $rm = $Conf->get('PuMA','rm');
my $run_cutadapt = $Conf->get('PuMA','run_cutadapt');
my $run_bowtie2 = $Conf->get('PuMA','run_bowtie2');
my $fastq2fasta = $Conf->get('PuMA','fastq2fasta');
my $run_diamond = $Conf->get('PuMA','run_diamond');
my $run_megan = $Conf->get('PuMA','run_megan');
my $convert_output = $Conf->get('PuMA','convert_output');

#########################################################
# End of Conf File settings 				#
#########################################################

#########################################################
# Start Main body of Program                            #
#########################################################

print "\n".&ascii_logo()."";
print "\n\033[31m\033[1m- Starting PuMA Pipeline -\033[0m\n";

# Perform this part in parallel
$files = scalar(@filenames) - 1;
$processes = scalar(@filenames);


#################################################
# Run Cutadapt on Files				#
#################################################
if($done_cutadapt eq "Yes") {
	print "\t\tAlready Finished \033[31m\033[1mcutadapt\033[0m on $rerundir\n";
} else {
   print "\n\tStarting cutadapt parallel parsing and filtering using $processes processes.\n";
   foreach $current_process (0..$files) {
	$file = $filenames[$current_process];
	$comments = $comments[$current_process];
	$run_id = basename($file);
	chdir("$workingdir/");

	$filehandle = "FILE" . $current_process;

	if($rerundir) {
		$rundir = $rerundir_full;
	} else {
        	$rundir = "$workingdir/$run_id.$$.dir";
	}

	if (!-d "$rundir") {
		(system "$mkdir","$rundir");
		if (!-d "$rundir") {
			print "\t Could not Make Directory needed to process data $rundir.\n";
			print `echo "\tCould not Make Directory needed to process data $rundir.\n" >> $logfile`;
			exit 0;
		}
	}

	$realfile = realpath($file);

	chdir("$rundir/");
        print `echo "Starting PuMA Pipeline\n\n" >> $logfile`;
        print `echo "files=$file\n" >> $logfile`;
        print `echo "adaptors=$adaptors\n" >> $logfile`;
        print `echo "conf_file=$conf_file\n" >> $logfile`;
        print `echo "debug=$debug\n" >> $logfile`;
        print `echo "\n" >> $logfile`;
        print `echo "Starting cutadapt parallel parsing and filtering using $processes processes.\n\n" >> $logfile`;

       	unless(-e "$realfile"){
       	        print "\t\t File $realfile does not exist!\n";
		exit 0;
       	}


	print "\t\tRunning \033[31m\033[1mcutadapt\033[0m on $run_id\n";
	print `echo "Running cutadapt" >> $logfile`;

       	$current_command = "$run_cutadapt -f $realfile -a $adaptors -l $logfile -r $run_id -c $conf_file";
	print `echo "command: $current_command" >> $logfile`;
       	open($filehandle,"| $current_command >>$logfile") or die "can't open CMD: $!"; # open pipe with command
    }

    # Wait for each cutadapt command to finish
    foreach $current_process (0..$files) {
    	my $filehandle = "FILE" . $current_process;
    	close $filehandle;
    }
    print `echo "====> Done with cutadapt <====" >> $logfile`;
    print "\tCompleted cutadapt parallel parsing and fastq files using $processes processes.\n\n";
}
#################################################
# End Cutadapt on Files				#
#################################################

#################################################
# Run Bowtie on Files				#
#################################################
if($done_bowtie2 eq "Yes") {
	print "\t\tAlready Finished \033[31m\033[1mbowtie2\033[0m on $rerundir\n";
} else {
    print "\tStarting bowtie2 parallel processing and alignment using $processes processes.\n";
    foreach $current_process (0..$files) {
	$file = $filenames[$current_process];
	$comments = $comments[$current_process];
	$run_id = basename($file);
	chdir("$workingdir/");


	$filehandle = "FILE" . $current_process;

	if($rerundir) {
		$rundir = $rerundir_full;
	} else {
        	$rundir = "$workingdir/$run_id.$$.dir";
	}

	chdir("$rundir/");
	print "\t\tRunning \033[31m\033[1mbowtie2\033[0m on $run_id\n";
	print `echo "Running bowtie2" >> $logfile`;

        $current_command = "$run_bowtie2 -f $run_id.cutadapt.out -l $logfile -r $run_id -c $conf_file";
	print `echo "command: $current_command" >> $logfile`;
        open($filehandle,"| $current_command >>$logfile") or die "can't open CMD: $!"; # open pipe with command

    }

    # Wait for each bowtie2 command to finish
    foreach $current_process (0..$files) {
        my $filehandle = "FILE" . $current_process;
        close $filehandle;
    }
    print `echo "====> Done with bowtie2 <====" >> $logfile`;
    print "\tCompleted bowtie2 parallel processing and alignment using $processes processes.\n\n";
}
#################################################
# End Bowtie on Files				#
#################################################

#################################################
# Run fastq2fasta on Files			#
#################################################
if($done_fastq2fasta eq "Yes") {
	print "\t\tAlready Finished \033[31m\033[1mfastq2fasta\033[0m on $rerundir\n";
} else {
    print "\tStarting to convert fastq files to fasta files in parallel processing using $processes processes.\n";
    foreach $current_process (0..$files) {
	$file = $filenames[$current_process];
	$comments = $comments[$current_process];
	$run_id = basename($file);
	chdir("$workingdir/");


	$filehandle = "FILE" . $current_process;

	if($rerundir) {
		$rundir = $rerundir_full;
	} else {
        	$rundir = "$workingdir/$run_id.$$.dir";
	}

	chdir("$rundir/");
	print "\t\tRunning \033[31m\033[1mfastq2fasta\033[0m on $run_id\n";
	print `echo "Running fastq2fasta" >> $logfile`;

        $current_command = "$fastq2fasta -f $run_id.bowtie2.out -l $logfile -o $run_id.bowtie2.fasta";
	print `echo "command: $current_command" >> $logfile`;
        open($filehandle,"| $current_command >>$logfile") or die "can't open CMD: $!"; # open pipe with command

    }

    # Wait for each fastq2fasta command to finish
    foreach $current_process (0..$files) {
        my $filehandle = "FILE" . $current_process;
        close $filehandle;
    }
    print `echo "====> Done with fastq2fasta <====" >> $logfile`;
    print "\tCompleted converting fastq files to fasta files in parallel processing using $processes processes.\n\n";
}
#################################################
# End fastq2fasta on Files			#
#################################################

#################################################
# Run diamond align on Files			#
#################################################
if($done_diamond eq "Yes") {
	print "\t\tAlready Finished \033[31m\033[1mdiamond\033[0m on $rerundir\n";
} else {
    print "\tStarting processing fasta files through diamond in parallel processing using $processes processes.\n";
    foreach $current_process (0..$files) {
	$file = $filenames[$current_process];
	$comments = $comments[$current_process];
	$run_id = basename($file);
	chdir("$workingdir/");


	$filehandle = "FILE" . $current_process;

	if($rerundir_full) {
		$rundir = $rerundir_full;
	} else {
        	$rundir = "$workingdir/$run_id.$$.dir";
	}

	chdir("$rundir/");
	print "\t\tRunning \033[31m\033[1mdiamond\033[0m on $run_id\n";
	print `echo "Running diamond" >> $logfile`;

        $current_command =  "$run_diamond -f $run_id.bowtie2.fasta -l $logfile -r $run_id -c $conf_file";
	print `echo "command: $current_command" >> $logfile`;
        open($filehandle,"| $current_command >>$logfile") or die "can't open CMD: $!"; # open pipe with command

    }

    # Wait for each diamond command to finish
    foreach $current_process (0..$files) {
        my $filehandle = "FILE" . $current_process;
        close $filehandle;
    }
    print `echo "====> Done with diamond <====" >> $logfile`;
    print "\tCompleted processing fasta files through diamond in parallel processing using $processes processes.\n\n";
}
#################################################
# End diamond on Files		  		#
#################################################

#################################################
# Run MEGAN on Files				#
#################################################
if($done_MEGAN eq "Yes") {
	print "\t\tAlready Finished \033[31m\033[1mMEGAN\033[0m on $rerundir\n";
} else {
    print "\tStarting processing data through MEGAN in parallel processing using $processes processes.\n";
    foreach $current_process (0..$files) {
	$file = $filenames[$current_process];
	$comments = $comments[$current_process];
	$run_id = basename($file);
	chdir("$workingdir/");


	$filehandle = "FILE" . $current_process;

	if($rerundir) {
		$rundir = $rerundir_full;
	} else {
        	$rundir = "$workingdir/$run_id.$$.dir";
	}

	chdir("$rundir/");
	print "\t\tRunning \033[31m\033[1mMEGAN\033[0m on $run_id\n";
	print `echo "Running MEGAN" >> $logfile`;

        $current_command =  "$run_megan -f $run_id.diamond.tsv -l $logfile -r $run_id -c $conf_file";
	print `echo "command: $current_command" >> $logfile`;
        open($filehandle,"| $current_command >>$logfile") or die "can't open CMD: $!"; # open pipe with command

    }

    # Wait for each MEGAN command to finish
    foreach $current_process (0..$files) {
        my $filehandle = "FILE" . $current_process;
        close $filehandle;
    }
    print `echo "====> Done with MEGAN <====" >> $logfile`;
    print "\tCompleted processing data through MEGAN in parallel processing using $processes processes.\n\n";
}
#################################################
# End MEGAN on Files		  		#
#################################################

chdir("$workingdir/");

#################################################
# Run Convert on Files				#
#################################################
if($done_Convert eq "Yes") {
	print "\t\tAlready Finished \033[31m\033[1mConvert\033[0m on $rerundir\n";
} else {
    print "\tStarting to convert the data to csv output in parallel processing using $processes processes.\n";
    foreach $current_process (0..$files) {
	$file = $filenames[$current_process];
	$comments = $comments[$current_process];
	$run_id = basename($file);
	chdir("$workingdir/");

	$filehandle = "FILE" . $current_process;

	if($rerundir) {
		$rundir = $rerundir_full;
	} else {
        	$rundir = "$workingdir/$run_id.$$.dir";
	}

	print "\t\tRunning \033[31m\033[1mconversion\033[0m to tab output on $run_id\n";
	print `echo "Running conversion to tab output" >> $rundir/$logfile`;

        $current_command =  "$convert_output -r $rundir -l $rundir/$logfile -o $rundir/all_counts.tsv";
	print `echo "command: $current_command" >> $rundir/$logfile`;
        open($filehandle,"| $current_command >>$rundir/$logfile") or die "can't open CMD: $!"; # open pipe with command

    }

    # Wait for each Convert command to finish
    foreach $current_process (0..$files) {
        my $filehandle = "FILE" . $current_process;
        close $filehandle;
    }
    print `echo "====> Done with Convert <====" >> $rundir/$logfile`;
    print "\tCompleted converting the data to csv output in parallel processing using $processes processes.\n\n";
}
#################################################
# End Convert on Files		  		#
#################################################

chdir("$workingdir/");

#################################################
# Run Clean Up on Files				#
#################################################
if($done_Clean eq "Yes") {
	print "\t\tAlready Finished \033[31m\033[1mClean\033[0m on $rerundir\n";
} else {
    print "\tStarting clean up of temporary files.\n";
    foreach $current_process (0..$files) {
	$file = $filenames[$current_process];
	$comments = $comments[$current_process];
	$run_id = basename($file);
	chdir("$workingdir/");


	$filehandle = "FILE" . $current_process;

	if($rerundir) {
		$rundir = $rerundir_full;
	} else {
        	$rundir = "$workingdir/$run_id.$$.dir";
	}

	chdir("$rundir/");
	if($debug == 0) {
		print "\t\tStarting to \033[31m\033[1mdelete temporary\033[0m files on $run_id\n";
		print `echo "Running clean up" >> $logfile`;
		print `echo "command: $rm $run_id.*" >> $logfile`;
		(system "$rm","$run_id.bowtie2.fasta");
		(system "$rm","$run_id.bowtie2.out");
		(system "$rm","$run_id.bowtie2.host");
		(system "$rm","$run_id.cutadapt.out");
		(system "$rm","$run_id.diamond.daa");
		(system "$rm","$run_id.diamond.tsv");
		(system "$rm","$run_id.MEGAN-Cmds.txt");
 	} 

 	print "\t\tYour Output Directory for $run_id is \"$rundir\".\n\n";
	chdir("$workingdir/");
    }
    print `echo "====> Done with Clean <====" >> $rundir/$logfile`;
    print "\tCompleted clean up of temporary files.\n\n";
}
#################################################
# End Clean Up on Files		  		#
#################################################


chdir("$workingdir/");
print "\033[31m\033[1m- Done Processing Data through PuMA Pipeline -\033[0m\n\n";

exit;

#########################################################
# End Main body of Program                            	#
#########################################################

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
# and is it the correct info.. if not go to the menu.   #
# if we came from the web it should all check out.      #
#########################################################

sub var_check {
	if ($opt_r) {                      
		$rerundir = $opt_r;
	} else {
		# Grab list of files to process
		if ($opt_f) {                      
			@filenames = parse_into_array($opt_f);
			foreach my $thisfile (@filenames){
				croak("Error: file '$thisfile' does not exist\n") if (! -r $thisfile);
			}
		} else {
			&var_error();
		}
	
		# Location of the adapters file:
		if ($opt_a) {
			$adaptors = $opt_a;
		}

        	if ($opt_c) {
        	        $conf_file = $opt_c;
        	} else {
        	        $conf_file = "$Bin/conf/example.conf";
        	}

        	if ($opt_d) {
        	        $debug = 1;
        	}
	}

	
}

#########################################################
# End of Varriable Check Subroutine "var_check"         #
#########################################################

#########################################################
# Start of Varriable error Subroutine "var_error"       #
#########################################################

sub var_error {
        print "\n".&ascii_logo()."";
	print "\n";
	print "\n\t\033[31m\033[1m PuMA Pipeline \033[0m\n\n";
	print "\t puma.pl is the main controler script for the entire PuMA Pipeline. It is used to call\n";
	print "\t all other tools within the PuMA software package. This tool requires a complete installation of PuMA Pipeline.\n";
	print "\t \n\n";
	print "\t You did not provide all the correct command line arguments\n\n";
	print "\t Usage:\n";
	print "\t puma.pl -f <dataFiles> -a <adapters> -c <configuration file> -d\n";
	print "\n\n ";
	print "\t -f   The Datafile(s) containing your sequence data. For Example:\n";
	print "\t\t-f 's_1_sequences.fastq'\n";
	print "\t\t-f 's_[1-7]_sequences.fastq'\n";
	print "\t\t-f 's_[1-4]_sequences.fastq;s_[6-7]_sequences.fastq'\n";
	print "\t -a   Input file of adaptor sequences (one per line).\n";
	print "\t\t-a adaptors.txt\n";
	print "\n";
	print "\t -c   The run configuration file (default = $Bin/conf/example.conf).\n";
	print "\t\t-c example.conf\n";
	print "\n";
	print "\t -r   The run directory for rerunning a failed run. When using this do not use any other options\n";
        print "\t      Example:\n";
        print "\t\tpuma.pl -r s_1_sequences.fastq.10001.dir\n";
	print "\n";
	print "\t -d   Debug mode: Keep all intermediate files.\n";
	print "\n";
	print "\n";
	print "\n\n\n";
	exit 0;
}

#########################################################
# End of Varriable error Subroutine "var_error"         #
#########################################################
