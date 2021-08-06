#!/usr/bin/env bats

# https://github.com/bats-core/bats-core

NUMCPUS=1
THISDIR=$BATS_TEST_DIRNAME
BINDIR="$THISDIR/../bin"

export PATH=$BINDIR:$PATH
export PATH=$BINDIR/sratoolkit.2.11.0-ubuntu64/bin:$PATH
export PATH=$BINDIR/edirect:$PATH
export PATH=$THISDIR/../scripts:$PATH
run mkdir -pv $BINDIR

