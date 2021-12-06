# Methods Questions

If you have questions regarding the methods for dataset curation or want clarification please submit a pull request and we will add to this document over time. Full details on methods and QC metrics will be provided in a forth coming publication, but we felt the importance of the dataset required that we release it before the paper was completely written. 

## QC methods

First, we ran [Fastqc](https://github.com/s-andrews/FastQC) to evaluate the basic quality. Next, with [Samtools](http://www.htslib.org/) we used Wuhan-1 (NCBI Reference Sequence: NC_045512.2) as the reference to calculate mean and standard deviation of the depth per nucleotide. Additionally, we provided a count of the number of nucleotides with the our depth cut off (<10 for Illumina and <20 for nanopore). 

Further, QC on all the datasets was done as part of [Titan v1.4.4](https://github.com/theiagen/public_health_viral_genomics), which is a pipeline that has its origins in the public health ([StaPH-B](http://www.staphb.org/)) community and is now underactive development from Theiagen. This is a containerized pipeline and it is [available on bioconda](https://bioconda.github.io/recipes/titan-gc/README.html). There is a pipeline for Illumina and for ONT so depending on the datatype we used one of those. Details about the pipeline and the outputs are found on their [Read the Docs](https://public-health-viral-genomics-theiagen.readthedocs.io/en/latest/titan_workflows.html#titan-illumina-pe). 

**NOTE: The default for Titan is to use [UShER](https://www.nature.com/articles/s41588-021-00862-7) for lineage calls.**
The container for [Pangolin v3.1.3 (PangoLEARN 2021-06-15)](https://hub.docker.com/layers/staphb/pangolin/3.1.3-pangolearn-2021-06-15/images/sha256-bb39b340c26201229d334e586aa24d3417e468eba5ceb1671b4ab45961d18d05?context=explore). Has the following dependencies in it:  

- UShER v0.3.1  
- Scorpio v0.3.1
- Constellations v0.0.5
- PangoLEARN 2021-06-15
- Pangolin v3.1.3
- pango-designations v1.2.13 used for pangoLEARN and UShER training  

As was stated in our presentation for SPHERES, important lineages in this paper are defined as CDC defined variant of concern (VOC) or variant of interest (VOI) lineages as of May 30th, 2021. We selected for lineage-determining spike mutations while minimizing the number of SNP differences (as determined by [Snippy](https://github.com/tseemann/snippy)) to the rest of the lineage. The non-VOC/VOI sequences came from Refseq, which is why we feel that are quite valuable. 
