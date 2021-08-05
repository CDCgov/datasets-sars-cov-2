# Author: Lee Katz <lkatz@cdc.gov>
 
SHELL   := /bin/bash

###################################

.DEFAULT: install

.PHONY: perl-modules

.DELETE_ON_ERROR:

install: perl-modules

perl-modules:
	@echo "good to go"
	#@perl -Mthreads -e 1 || (echo "ERROR: this version of perl does not have threads" && exit 1)
	#cpanm -v -L . Spreadsheet::XLSX
	#cpanm -v -L . Spreadsheet::ParseExcel
