#!/usr/bin/env bats

# https://github.com/bats-core/bats-core

load "inc/environment"
run mkdir -pv $BINDIR

@test "Download edirect" {
  if [[ -e "$BINDIR/edirect/esearch" ]]; then
    skip "Esearch already exists"
  fi

  echo "# Downloading with perl -MNet::FTP" >&3
  perl -MNet::FTP -e \
      '$ftp = new Net::FTP("ftp.ncbi.nlm.nih.gov", Passive => 1);
       $ftp->login; $ftp->binary;
       $ftp->get("/entrez/entrezdirect/edirect.tar.gz");' 
  echo "# Extracting to $BINDIR" >&3
  tar zxf edirect.tar.gz
  mv -n edirect $BINDIR
  rm -f edirect.tar.gz

  esearch -h
}

@test "Download sratoolkit" {
  if [[ -e "$BINDIR/sratoolkit.2.11.0-ubuntu64/bin/fastq-dump" ]]; then
    skip "Sra Toolkit already exists"
  fi

  echo "# Downloading with wget" >&3
  wget -c http://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz
  echo "# Extracting to $BINDIR" >&3
  tar zxvf sratoolkit.current-ubuntu64.tar.gz
  mv sratoolkit.2.11.0-ubuntu64 $BINDIR
  rm -f sratoolkit.current-ubuntu64.tar.gz
  vdb-config --restore-defaults

  fastq-dump -h
}

