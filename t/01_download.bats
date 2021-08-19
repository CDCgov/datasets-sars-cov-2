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

  note "Downloading DATASET $DATASET"
  name=$(basename $DATASET)
  run GenFSGopher.pl -o $BATS_SUITE_TMPDIR/$name.out --numcpus $NUMCPUS $DATASET
  #mkdir $BATS_SUITE_TMPDIR/$name.out;echo "foo" > $BATS_SUITE_TMPDIR/$name.out/bar.txt; run false
  exit_code="$status"
  note "Independently running sha256sum outside of GenFSGopher.pl"
  find $BATS_SUITE_TMPDIR -type f -exec sha256sum {} \; | sed 's/^/# /' >&3
  if [ "$exit_code" -gt 0 ]; then
    note "ERROR on GenFSGopher!"
    # invoke an exit code > 1 with 'false'
    false
  fi
  rm -rf $BATS_SUITE_TMPDIR/$name.out
}

