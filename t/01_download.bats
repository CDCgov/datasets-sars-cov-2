#!/usr/bin/env bats

# https://github.com/bats-core/bats-core

load "inc/environment"

function note(){
  echo "# $1" >&3
}

@test "Environment" {
  note "Looking for executables"
  note "============="
  which esearch | sed 's/^/# /' >&3
  which fastq-dump | sed 's/^/# /' >&3
  which GenFSGopher.pl | sed 's/^/# /' >&3

  note "Looking at environmental variables"
  note "============"
  if [[ -z "$DATASET" ]]; then
    note "No dataset was found in the environment variable DATASET"
    false
  fi
  note "DATASET: $DATASET"
}

@test "download dataset" {
  if [[ -z "$DATASET" ]]; then
    note "No dataset was found in the environment variable DATASET"
    false
  fi

  # Split the dataset into just 20 genomes each
  chunkSize=20
  note "Splitting DATASET $DATASET into chunks of $chunkSize samples"
  samples=$(grep -A 9999 -i biosample_acc "$DATASET" | tail -n +2)
  numSamples=$(echo "$samples" | wc -l)
  note "Number of samples: $numSamples";
  header=$(grep -B 99 -i biosample_acc "$DATASET")

  # Chunk all samples into different files with prefix TMPDATASET_
  echo "$samples" | split -l $chunkSize - TMPDATASET_
  chunks_counter=0
  for samplesfile in TMPDATASET_*; do
    chunks_counter=$((chunks_counter+1))
    # Make a file in.tsv that has the header and the samples
    echo "$header" > in.tsv
    cat $samplesfile >> in.tsv
    DATASET=in.tsv

    note "GenFSGopher.pl on chunk $chunks_counter"
    note " "
    cat $samplesfile | sed 's/^/# /' >&3
    note " "
    name=$(basename $DATASET)
    run GenFSGopher.pl -o $BATS_SUITE_TMPDIR/$name.out --compressed --numcpus $NUMCPUS $DATASET
    #mkdir $BATS_SUITE_TMPDIR/$name.out;echo "foo" > $BATS_SUITE_TMPDIR/$name.out/bar.txt; run false
    exit_code="$status"
    note "$output"
    note "Independently running sha256sum outside of GenFSGopher.pl"
    find $BATS_SUITE_TMPDIR -type f -exec sha256sum {} \; | sed 's/^/# /' >&3
    find $BATS_SUITE_TMPDIR -type f -name '*.gz' | xargs -n 1 bash -c 'echo -ne "$0\t"; gzip -cd $0 | sha256sum' | sed 's/^/# /' >&3
    if [ "$exit_code" -gt 0 ]; then
      note "ERROR on GenFSGopher! exit code $exit_code"
      # invoke an exit code > 1 with 'false'
      false
    fi
    rm -rf $BATS_SUITE_TMPDIR/$name.out in.tsv
  done
  rm TMPDATASET_* -v
}

