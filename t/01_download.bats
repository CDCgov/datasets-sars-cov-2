#!/usr/bin/env bats

# https://github.com/bats-core/bats-core

load "inc/environment"

@test "executables in path" {
  which esearch
  which fastq-dump
  which GenFSGopher.pl
}

@test "download datasets" {
  for dataset in $BATS_TEST_DIRNAME/../datasets/*.tsv; do
    echo "# Downloading $dataset" >&3
    name=$(basename $dataset)
    GenFSGopher.pl -o $BATS_SUITE_TMPDIR/$name.out --numcpus $NUMCPUS $dataset 2>&1
  done
}

