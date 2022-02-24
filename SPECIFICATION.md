# Dataset specification

1. The first part describes the dataset.  This is given as a two-column key/value format.  The keys are case-insensitive, but the values are case-sensitive.  The order of rows is unimportant.
    1. Organism.  Usually genus and species, but there is no hard rule at this time.
    2. Outbreak.  This is usually an outbreak code but can be some other descriptor of the dataset.
    3. pmid.  Any publications associated with this dataset should be listed as pubmed IDs.
    4. tree.  This is a URL to the newick-formatted tree.  This tree serves as a guide to future analyses.
    5. source. Where did this dataset come from?
    6. intendedUsage.  How do you think others will use this dataset?
3. Blank row - separates the two parts of the dataset
4. Header row with these names (case-insensitive, in any order): biosample_acc, ...
5. Sample info.  Each row represents a genome and must have the following fields.  Use a dash (-) for any missing data.
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


