#!/usr/bin/env bats

# https://github.com/bats-core/bats-core

NUMCPUS=2
THISDIR=$BATS_TEST_DIRNAME
BINDIR="$THISDIR/../bin"

export PATH=$PATH:$BINDIR
export PATH=$PATH:$BINDIR/sratoolkit.2.11.0-ubuntu64/bin
export PATH=$PATH:$BINDIR/edirect
run mkdir -pv $BINDIR

