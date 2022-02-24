#!/usr/bin/env perl
# this is from https://github.com/lskatz/CG-Pipeline/blob/master/scripts/run_assembly_shuffleReads.pl
# shuffle or deshuffle sequences.  Good for fastq files only right now.
# Author: Lee Katz <lkatz@cdc.gov>

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use IO::Compress::Gzip qw(gzip);

# TODO If only one file to shuffle, just output the first SE file to stdout


local $SIG{'__DIE__'} = sub { my $e = $_[0]; $e =~ s/(at [^\s]+? line \d+\.$)/\nStopped $1/; die("$0: ".(caller(1))[3].": ".$e); };
exit(main());

sub main{
  local $0=fileparse $0;
  my $settings={};
  GetOptions($settings,qw(deshuffle help gzip));
  die usage($settings) if($$settings{help});

  for(@ARGV){
    die "ERROR: Could not find file $_" if(! -f $_);
  }

  my $numReads;
  if($$settings{deshuffle}){
    die "ERROR: need a file to deshuffle\n". usage() if(@ARGV<1);
    my($seqFile)=@ARGV;
    $numReads=deshuffleSeqs($seqFile,$settings);
  } else {
    die "ERROR: need >two files to shuffle\n". usage() if(@ARGV<2);
    die "ERROR: need an even number of files to shuffle\n".usage() if(@ARGV % 2==1);
    my @seqFile=@ARGV;
    $numReads=shuffleSeqs(\@seqFile,$settings);
  }
  return 0;
}

sub is_gzipped{
  my($file,$settings)=@_;
  my($name,$path,$suffix)=fileparse($file,qw(.gz));
  if($suffix eq '.gz'){
    return 1;
  }
  return 0;
}

sub deshuffleSeqs{
  my($seqFile,$settings)=@_;

  # set up the output filehandles if the user wants gzipped output
  my $stdout = *STDOUT;
  my $stderr = *STDERR;
  if($$settings{gzip}){
    $stdout = new IO::Compress::Gzip '-';
    $stderr = new IO::Compress::Gzip '/dev/stderr';
  }

  if(is_gzipped($seqFile,$settings)){
    open(SHUFFLED,"gunzip -c '$seqFile' |") or die "Could not open/gunzip shuffled fastq file $seqFile: $!";
  } else {
    open(SHUFFLED,"<",$seqFile) or die "Could not open shuffled fastq file $seqFile: $!";
  }
  my $i=0;
  while(<SHUFFLED>){
    my $mod=$i%8;
    if($mod<4){
      print $stdout $_;
    } elsif($mod>=4) {
      print $stderr $_;
    } else {
      die "Internal error";
    }
    
    $i++;
  }
  close SHUFFLED;
  my $numReads=$i/4;
  return $numReads;
}

sub shuffleSeqs{
  my($seqFile,$settings)=@_;
  my $i=0;
  my $fp = *STDOUT;
     $fp=new IO::Compress::Gzip '-' if($$settings{gzip});
  for(my $j=0;$j<@$seqFile;$j+=2){
    my($file1,$file2)=($$seqFile[$j],$$seqFile[$j+1]);
    if(is_gzipped($file1,$settings)){
      open(MATE1,"gunzip -c '$file1' |") or die "Could not open $file1: $!";
    } else {
      open(MATE1,"<",$file1) or die "Could not open $file1: $!";
    }
    if(is_gzipped($file2,$settings)){
      open(MATE2,"gunzip -c '$file2' |") or die "Could not open $file2: $!";
    } else {
      open(MATE2,"<",$file2) or die "Could not open $file2: $!";
    }
    while(my $out=<MATE1>){
      $out.=<MATE1> for(1..3);
      my $out2=<MATE2>;
      $out2.=<MATE2> for(1..3);

      if(!$out2){
        print STDERR "WARNING: there are more lines in $file1 than in $file2! I will not continue reading $file1\n";
        last;
      }

      print $fp "$out$out2";
      $i++;
    }
    # Check for a longer read2 file
    my $more_mate2=<MATE2>;
    if($more_mate2){
      print STDERR "WARNING: there are more lines in $file2 than in $file1! I will not continue reading $file2\n";
    }

    close MATE1; close MATE2;
  }
  my $numReads=$i/4;
  return $numReads;
}

sub usage{
  my ($settings)=@_;
  local $0=fileparse($0);
  my $help="Shuffle or deshuffle sequences
  Usage:           $0 file_1.fastq file_2.fastq > shuffled.fastq
  Alternate Usage: $0 -d shuffled.fastq > file_1.fastq 2> file_2.fastq
  NOTE: Due to the double redirection, error messages are hidden when deshuffling. A user should check the exit code to see if the program executed correctly.
    -d for deshuffle
    -gz for gzipped output (including stderr)
    -h for additional help";
  return $help if(!$$settings{help});
  $help.="
  EXAMPLES
  $0 file_[12].fastq > shuffled.fastq
  $0 file_[12].fastq -gz > shuffled.fastq.gz
  $0 file_[12].fastq > gzip -c > shuffled.fastq.gz
  $0 -d file.shuffled.fastq[.gz] 1> forward.fastq 2> reverse.fastq
  $0 -d file.shuffled.fastq[.gz] -gz 1> forward.fastq.gz 2> reverse.fastq.gz
  "
}
