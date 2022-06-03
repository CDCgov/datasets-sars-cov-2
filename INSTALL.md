# Installation from other sources

The community generously maintains the following methods of installation.
For installing from source, please see the relevant section in [README.md](README.md).

An NCBI API key is required to use this tool. [See here for information on how to obtain your own NCBI API key](https://ncbiinsights.ncbi.nlm.nih.gov/2017/11/02/new-api-keys-for-the-e-utilities/)

## Conda 
*datasets-sars-cov-2* is available on [BioConda](https://bioconda.github.io/recipes/uscdc-datasets-sars-cov-2/README.html)
```bash
conda create -n datasets-sars-cov-2 -c conda-forge -c bioconda uscdc-datasets-sars-cov-2

conda activate datasets-sars-cov-2

export NCBI_API_KEY="<your-NCBI-API-key-here>"

# the path to the input TSV may differ depending on how & where you installed conda; below is default location for miniconda3 installed on linux
GenFSGopher.pl --numcpus 8 --compressed --outdir vocvoi-dataset ~/miniconda3/envs/datasets-sars-cov-2/share/uscdc-datasets-sars-cov-2/sars-cov-2-voivoc.tsv
```

## Docker
The [StaPH-B working group](https://staphb.org/) maintains a [docker image](https://hub.docker.com/r/staphb/datasets-sars-cov-2) for *datasets-sars-cov-2*. The dockerfile can be found [here](https://github.com/StaPH-B/docker-builds/tree/master/datasets-sars-cov-2/).

The input TSVs are located here within the StaPH-B docker image: `/home/user/datasets-sars-cov-2/datasets/`

There is also a [BioContainer docker image](https://quay.io/repository/biocontainers/uscdc-datasets-sars-cov-2?tab=tags) which contains the (bio)conda environment for this repository. The example below uses the StaPH-B docker image, but similar commands can be used with the BioContainer docker image. The input TSVs are located here within the BioContainer docker image: `/usr/local/share/uscdc-datasets-sars-cov-2/`
```bash
docker pull staphb/datasets-sars-cov-2:latest

# broken into 2 lines for readability
docker run --rm -v $PWD:/data -u $(id -u):$(id -g) staphb/datasets-sars-cov-2:latest /bin/bash -c \
'export NCBI_API_KEY="<your-NCBI-API-key-here>"; GenFSGopher.pl --numcpus 8 --compressed --outdir /data/vocvoi-dataset /home/user/datasets-sars-cov-2/datasets/sars-cov-2-voivoc.tsv'
```

## Singularity
The StaPH-B docker image can be converted to singularity image format and utilitzed in a similar manner.
```bash
singularity build staphb.datasets-sars-cov-2.sif docker://staphb/datasets-sars-cov-2:latest

# broken into 3 lines for readabilty
singularity exec -B $PWD:/data --no-home staphb.datasets-sars-cov-2.sif /bin/bash -c \
"export HOME=/home/user; export NCBI_API_KEY="<your-NCBI-API-key-here>"; \
GenFSGopher.pl --numcpus 8 --compressed --outdir /data/vocvoi-dataset /home/user/datasets-sars-cov-2/datasets/sars-cov-2-voivoc.tsv"
```
