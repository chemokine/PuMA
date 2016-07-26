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
#
# Makefile v1.0 for PuMA Pipeline
# Date: Feb 21th, 2016
#
#########################################################

CC         = c++
INSTALLDIR = bin
CWD	   = `pwd`
CAT        = cat
DEL        = rm
COPY	   = cp
XVFBRUN	   = xvfb-run
ECHO	   = echo
ECHON	   = echo -n
CONF       = conf
RUN_APT	   = $(CWD)/pipeline/run_cutadapt.pl
RUN_BT2	   = $(CWD)/pipeline/run_bowtie2.pl
RUN_F2F	   = $(CWD)/pipeline/fastq2fasta.pl
RUN_DIA	   = $(CWD)/pipeline/run_diamond.pl
RUN_MEG	   = $(CWD)/pipeline/run_megan.pl
RUN_COV	   = $(CWD)/pipeline/convert_output.pl

CUTADAPT_CMD  = /local/cluster/bin/cutadapt

BOWTIE2_CMD   = /local/cluster/bin/bowtie2
BT2DB_PATH    = /dbase/genomes/BOWTIE/Homo_sapien/hg19-bt2

DIAMOND_CMD   = /local/cluster/bin/diamond
DIADB_PATH    = /capecchi/pharmacy/morgunlab/MetagenomicsWorkflowWithCGRB/testing_directory/all.bac.fungi.virus.microbe_10000.dmnd

MEGAN_CMD     = /local/cluster/bin/MEGAN
MEGAN_LIC     = /local/cluster/megan/MEGAN5-academic-license.txt
TGIF_PATH     = /capecchi/pharmacy/morgunlab/MetagenomicsWorkflowWithCGRB/testing_directory/gi2taxid.bin
SGIF_PATH     = /capecchi/pharmacy/morgunlab/MetagenomicsWorkflowWithCGRB/testing_directory/gi2seed.bin
KGIF_PATH     = /capecchi/pharmacy/morgunlab/MetagenomicsWorkflowWithCGRB/testing_directory/gi2kegg.bin

all : config_file
.PHONY: install

config_file :
	@$(ECHON) "Building the PuMA config file.... "
	@$(ECHO) "[PuMA]" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "cp                      = $(COPY)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "rm                      = $(DEL)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "mkdir                   = mkdir" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "xvfbrun                 = $(XVFBRUN)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "fastq2fasta             = $(RUN_F2F)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "convert_output          = $(RUN_COV)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "run_cutadapt            = $(RUN_APT)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "run_bowtie2             = $(RUN_BT2)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "run_diamond             = $(RUN_DIA)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "run_megan               = $(RUN_MEG)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "[Cutadapt]" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "cutadapt                = $(CUTADAPT_CMD)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "cutadapt_options        = -e 0.2 -O 5 -m 60" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "[Bowtie2]" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "bowtie2                 = $(BOWTIE2_CMD)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "bowtie2_db              = $(BT2DB_PATH)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "bowtie2_options         = -p 1" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "[Diamond]" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "diamond                 = $(DIAMOND_CMD)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "diamond_db              = $(DIADB_PATH)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "diamond_options         = -p 1" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "[MEGAN]" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "megan                   = $(MEGAN_CMD)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "megan_options           = -MC 1" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "meganLicense            = $(MEGAN_LIC)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "taxGIFile               = $(TGIF_PATH)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "seedGIFile              = $(SGIF_PATH)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "keggGIFile              = $(KGIF_PATH)" >> $(CWD)/conf/example.conf.new
	@$(ECHO) "" >> $(CWD)/conf/example.conf.new
	@$(COPY) -f $(CWD)/conf/example.conf.new $(CWD)/conf/example.conf
	@$(DEL)  -f $(CWD)/conf/example.conf.new
	@$(ECHO)  "[ OK ]"


clean :
	@$(ECHON) "Removing default PuMA config file.... "
	@$(DEL) $(CWD)/conf/example.conf
	@$(ECHO)  "[ OK ]"

