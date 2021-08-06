#!/usr/bin/env bats

# https://github.com/bats-core/bats-core

load "inc/environment"

@test "executables in path" {
  which esearch
  which fastq-dump
  which GenFSGopher.pl
}

@test "download datasets" {
  if [[ -z "$DATASET" ]]; then
    skip "No dataset was found in the environment variable DATASET"
  fi

  echo "# Downloading $DATASET" >&3
  name=$(basename $DATASET)
  GenFSGopher.pl -o $BATS_SUITE_TMPDIR/$name.out --numcpus $NUMCPUS $DATASET 2>&3 1>&3
}

