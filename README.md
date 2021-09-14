This document is under governance review. When the review completes as appropriate per local and agency processes, the project team will be allowed to remove this notice. This material is draft.

# Datasets
Benchmark datasets for WGS analysis of SARS-CoV-2.

## Purpose
Technical Outreach and Assistance for States Team (TOAST) developed benchmark datasets for SARS-CoV-2 sequencing which are designed to help users at varying stages of building sequencing capacity. It consists of six datasets summarized in the table below, each chosen to represent a different use case.

## Summary Table
| Dataset  | Name | Description | Intended Use |
| ------------- | ------------- | ------------- | ------------- | 
| 1 | Boston Outbreak   | A cohort of 63 samples from a real outbreak with three introductions, metagenomic approach  | To understand the features of virus transmission during real outbreak setting   |
| 2 | CoronaHit rapid   | A cohort of 39 samples prepared by 18 hr wet-lab protocol and sequenced by two platforms (Illumina vs MinIon), amplicon-based approach  | To verify that a bioinformatics pipeline finds virtually no differences between platforms of the same genome  |
| 3 | CoronaHit routine | A cohort of 69 samples prepared by 30 hr wet-lab protocol and sequenced by two platforms (Illumina vs MinIon), amplicon-based approach  | To verify that a bioinformatics pipeline finds virtually no differences between platforms of the same genome  |
| 4 | VOI/VOC lineages  | A cohort of 16 samples from 11 representative CDC defined VOI/VOC lineages as of 05/30/2021, amplicon-based approach  | To benchmark lineage-calling bioinformatics software, especially for VOI/VOCs |
| 5 | Non-VOI/VOC lineages | A cohort of 39 samples from representative non VOI/VOC lineages, amplicon-based approach | To benchmark lineage-calling bioinformatics software, nonspecific to VOI/VOCs  |
| 6 | Failed QC | A cohort of 24 samples failed basic QC metrics, covering 8 possible failure scenarios, amplicon-based approach  | To serve as controls to test bioinformatics QC cutoffs |

## Installation

Grab the latest stable release under the releases tab.  If you are feeling adventurous, use `git clone`!  Include the scripts directory in your path.  For example, if you downloaded this project into your local bin directory:

    $ export PATH=$PATH:$HOME/bin/datasets/scripts

Additionally, ensure that you have the [NCBI API key](https://ncbiinsights.ncbi.nlm.nih.gov/2017/11/02/new-api-keys-for-the-e-utilities).
This key associates your edirect requests with your username.
Without it, edirect requests might be buggy.
After obtaining an NCBI API key, add it to your environment with

    export NCBI_API_KEY=unique_api_key_goes_here

where `unique_api_key_goes_here` is a unique hexadecimal number with characters from 0-9 and a-f.

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

**NOTE**: edirect needs an NCBI API key.
Instructions can be found at https://ncbiinsights.ncbi.nlm.nih.gov/2017/11/02/new-api-keys-for-the-e-utilities

### Installing sha256sum

If you do not have sha256sum (e.g., if you are on MacOS), then try to make the shell function and export it.

    function sha256sum() { shasum -a 256 "$@" ; }
    export -f sha256sum

This shell function will need to be defined in the current session. To make it permanent for future sessions, add it to `$HOME/.bashrc`.

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

If this project has helped you, please cite both this website and the original publication:

Timme, Ruth E., et al. "Benchmark datasets for phylogenomic pipeline validation, applications for foodborne pathogen surveillance." PeerJ 5 (2017): e3893.

[![Build Status](https://travis-ci.org/globalmicrobialidentifier-WG3/datasets.svg?branch=master)](https://travis-ci.org/globalmicrobialidentifier-WG3/datasets)

---
## Notices and Disclaimers

### Public Domain
This repository constitutes a work of the United States Government and is not subject to domestic copyright protection under 17 USC § 105. This repository is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/). All contributions to this repository will be released under the CC0 dedication. By submitting a pull request you are agreeing to comply with this waiver of
copyright interest.

### License

Unless otherwise specified, the repository utilizes code licensed under the terms of the Apache Software License and therefore is licensed under ASL v2 or later.

This source code in this repository is free: you can redistribute it and/or modify it under the terms of the Apache Software License version 2, or (at your option) any later version.

This source code in this repository is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the Apache Software License for more details.

You should have received a copy of the Apache Software License along with this program. If not, see http://www.apache.org/licenses/LICENSE-2.0.html

Any source code forked from other open source projects will inherit its license.

### Privacy

This repository contains only non-sensitive, publicly available data and information. All material and community participation is covered by the [Disclaimer](https://github.com/CDCgov/template/blob/master/DISCLAIMER.md) and [Code of Conduct](https://github.com/CDCgov/template/blob/master/code-of-conduct.md).For more information about CDC's privacy policy, please visit [http://www.cdc.gov/other/privacy.html](https://www.cdc.gov/other/privacy.html).

### Contributing

Anyone is encouraged to contribute to the repository by [forking](https://help.github.com/articles/fork-a-repo) and submitting a pull request. (If you are new to GitHub, you might start with a [basic tutorial](https://help.github.com/articles/set-up-git).) By contributing to this project, you grant a world-wide, royalty-free, perpetual, irrevocable, non-exclusive, transferable license to all users under the terms of the [Apache Software License v2](http://www.apache.org/licenses/LICENSE-2.0.html) or later.

All comments, messages, pull requests, and other submissions received through CDC including this GitHub page may be subject to applicable federal law, including but not limited to the Federal Records Act, and may be archived. Learn more at [http://www.cdc.gov/other/privacy.html](http://www.cdc.gov/other/privacy.html).

### Records

This repository is not a source of government records, but is a copy to increase collaboration and collaborative potential. All government records will be published through the [CDC web site](http://www.cdc.gov).
