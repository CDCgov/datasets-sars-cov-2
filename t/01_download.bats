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
  run GenFSGopher.pl -o $BATS_SUITE_TMPDIR/$name.out --numcpus $NUMCPUS $DATASET 2>&3 1>&3
  if [[ "$status" -gt 1 ]]; then
    echo "# ERROR on GenFSGopher! Running sha256sums in case it helps correct the spreadsheet"
    for file in $BATS_SUITE_TMPDIR/$name.out/*; do
      run file $file
      run ls -lh $file
      run sha256sum $file
    done | sed 's|^|# ' >&3
    
    # invoke an exit code > 1 with 'false'
    false
  fi
}

