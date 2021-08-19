#!/usr/bin/env bats

# https://github.com/bats-core/bats-core

NUMCPUS=24
THISDIR=$BATS_TEST_DIRNAME
BINDIR="$THISDIR/../bin"

export PATH=$BINDIR:$PATH
export PATH=$BINDIR/sratoolkit.2.11.0-ubuntu64/bin:$PATH
export PATH=$BINDIR/edirect:$PATH
export PATH=$THISDIR/../scripts:$PATH
run mkdir -pv $BINDIR

# special environment for CI environment
if [[ "$CI" == true ]]; then
  # Both travis and Github Actions have an env with 2 cpus
  NUMCPUS=2
fi

