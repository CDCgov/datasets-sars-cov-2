# datasets
Benchmark datasets for WGS analysis.

## Installation

Grab the latest stable release under the releases tab.  If you are feeling adventurous, use `git clone`!  Include the scripts directory in your path.  For example, if you downloaded this project into your local bin directory:

    $ export PATH=$PATH:$HOME/bin/datasets/scripts

### Dependencies

In addition to the installation above, please install the following.

1. edirect (see section on edirect below)
2. sra-toolkit, built from source: https://github.com/ncbi/sra-tools/wiki/Building-and-Installing-from-Source
3. Perl 5.12.0
4. Make
5. wget - Brew users: `brew install wget`
6. sha256sum - Linux-based OSs should have this already; Other users should see the relevant installation section below.

### Installing edirect

  Modified instructions from https://www.ncbi.nlm.nih.gov/books/NBK179288/

    mkdir -p ~/bin
    cd ~/bin
    perl -MNet::FTP -e \
      '$ftp = new Net::FTP("ftp.ncbi.nlm.nih.gov", Passive => 1);
       $ftp->login; $ftp->binary;
       $ftp->get("/entrez/entrezdirect/edirect.tar.gz");'
    gunzip -c edirect.tar.gz | tar xf -
    rm edirect.tar.gz
    export PATH=$PATH:$HOME/bin/edirect
    ./edirect/setup.sh

### Installing sha256sum

If you do not have sha256sum (e.g., if you are on MacOS), then try to make the shell function and export it.

    function sha256sum() { shasum -a 256 "$@" ; }
    export -f sha256sum

This shell function will need to be defined in the current session. To make it permanent for future sessions, add it to `$HOME/.bashrc`.

## For the impatient

We have included a script that downloads all datasets, runs the CFSAN SNP Pipeline, infers a phylogeny, and compares the tree against the suggested tree.  All example commands are present in the shell script for your manual inspection.

    $ bash EXAMPLES/downloadAll.sh

## Downloading a dataset
To run, you need a dataset in tsv format.  Here is the usage statement:

    Usage: GenFSGopher.pl -o outdir spreadsheet.dataset.tsv
    PARAM        DEFAULT  DESCRIPTION
    --outdir     <req'd>  The output directory
    --format     tsv      The input format. Default: tsv. No other format
                          is accepted at this time.
    --layout     onedir   onedir   - Everything goes into one directory
                          byrun    - Each genome run gets its separate directory
                          byformat - Fastq files to one dir, assembly to another, etc
                          cfsan    - Reference and samples in separate directories with
                                     each sample in a separate subdirectory
    --shuffled   <NONE>   Output the reads as interleaved instead of individual
                          forward and reverse files.
    --norun      <NONE>   Do not run anything; just create a Makefile.
    --numcpus    1        How many jobs to run at once. Be careful of disk I/O.
    --citation            Print the recommended citation for this script and exit
    --version             Print the version and exit
    --help                Print the usage statement and die

## Using a dataset

There is a field `intendedUse` which suggests how a particular dataset might be used.  For example, Epi-validated outbreak datasets might be used with a SNP-based or MLST-based workflow.  As the number of different values for `intendedUse` increases, other use-cases will be available.  Otherwise, how you use a dataset is up to you!

## Creating your own dataset
To create your own dataset and to make it compatible with the existing script(s) here, please follow these instructions.  These instructions are subject to change.

1. Create a new Excel spreadsheet with only one tab. Please delete any extraneous tabs to avoid confusion.
2. The first part describes the dataset.  This is given as a two-column key/value format.  The keys are case-insensitive, but the values are case-sensitive.  The order of rows is unimportant.
  1. Organism.  Usually genus and species, but there is no hard rule at this time.
  2. Outbreak.  This is usually an outbreak code but can be some other descriptor of the dataset.
  3. pmid.  Any publications associated with this dataset should be listed as pubmed IDs.
  4. tree.  This is a URL to the newick-formatted tree.  This tree serves as a guide to future analyses.
  5. source. Where did this dataset come from?
  6. intendedUsge.  How do you think others will use this dataset?
3. Blank row - separates the two parts of the dataset
4. Header row with these names (case-insensitive): biosample_acc, strain, genbankAssembly, SRArun_acc, outbreak, dataSetName, suggestedReference, sha256sumAssembly, sha256sumRead1, sha256sumRead2
4. Accessions to the genomes for download.  Each row represents a genome and must have the following fields.  Use a dash (-) for any missing data.
  1. biosample_acc - The BioSample accession
  2. strain - Its genome name
  3. genbankAssembly - GenBank accession number
  4. SRArun_acc - SRR accession number
  5. outbreak - The name of the outbreak clade.  Usually named after an outbreak code.  If not part of an important clade, the field can be filled in using 'outgroup'
  6. dataSetName - this should be redundant with the outbreak field in the first part of the spreadsheet
  7. suggestedReference - The suggested reference genome for analysis, e.g., SNP analysis.
  8. sha256sumAssembly - A checksum for the GenBank file 
  9. sha256sumRead1 - A checksum for the first read from the SRR accession
  10. sha256sumRead2 - A checksum for the second read from the SRR accession
  11. nucleotide - A single nucleotide accession. This is sometimes an alternative to an assembly especially for one-contig genomes.
  12. sha256sumnucleotide - a checksum for the single nucleotide accession.

## Citation

If this project has helped you, please cite us with

Timme, Ruth E., et al. "Benchmark datasets for phylogenomic pipeline validation, applications for foodborne pathogen surveillance." PeerJ 5 (2017): e3893.

[![Build Status](https://travis-ci.org/globalmicrobialidentifier-WG3/datasets.svg?branch=master)](https://travis-ci.org/globalmicrobialidentifier-WG3/datasets)
