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

  echo "# Downloading xtract" >&3
  nquire -dwn ftp.ncbi.nlm.nih.gov entrez/entrezdirect xtract.Linux.gz
  run gunzip -f xtract.Linux.gz
  run chmod +x xtract.Linux
  run mv -nv xtract.Linux $BINDIR/edirect/
  echo "# Downloading transmute" >&3
  nquire -dwn ftp.ncbi.nlm.nih.gov entrez/entrezdirect transmute.Linux.gz
  run gunzip -f transmute.Linux.gz
  run chmod +x transmute.Linux
  run mv -nv transmute.Linux $BINDIR/edirect/
}

@test "Download sratoolkit" {
  if [[ -e "$BINDIR/sratoolkit.2.11.0-ubuntu64/bin/fastq-dump" ]]; then
    skip "SRA Toolkit was already downloaded"
  else
    echo "# Found that the SRA Toolkit was not already downloaded by this script" >&3
  fi

  fastqDumpPath=$(which fastq-dump 2>/dev/null || true)
  if [[ "$fastqDumpPath" != "" ]]; then
    skip "SRA Toolkit was already installed elsewhere: $$fastqDumpPath"
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

