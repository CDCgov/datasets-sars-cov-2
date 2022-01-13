#!/usr/bin/env perl

# Creates a dataset spreadsheet
# 
# Author: Lee Katz <gzu2@cdc.gov>
# WGS standards and analysis group

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use File::Basename qw/fileparse dirname basename/;
use File::Temp qw/tempdir tempfile/;
use File::Spec;
use File::Copy qw/cp mv/;
use File::Which qw/which/;

use Digest::SHA qw/sha256/;

my $scriptInvocation=join(" ",$0,@ARGV);
my $scriptsDir=dirname(File::Spec->rel2abs($0));
local $0=basename $0;
sub logmsg{print STDERR "$0: @_\n";}

exit main();

sub main{
  my $settings={};
  GetOptions($settings,qw(help stop-at=i tempdir=s)) or die $!;
  #$$settings{tempdir}||=tempdir(basename($0).".XXXXXX",TMPDIR=>1,CLEANUP=>1);
  #logmsg "Temp dir is $$settings{tempdir}";

  usage() if($$settings{help} || !@ARGV);

  # Check execs in the path
  for(qw(esearch elink efetch xtract fastq-dump)){
    system("which $_ > /dev/null");
    which($_) or die "ERROR: $_ not in path!";
  }

  for my $dataset(@ARGV){
    my $spreadsheet = "$dataset/in.tsv";
    my $info = readSpreadsheet($spreadsheet, $settings);
    my $newInfo = updateChecksums($info, $settings);
    my $newTsv = formatSpreadsheet($newInfo, $settings);
    print $newTsv;
  }

  return 0;
}

sub formatSpreadsheet{
  my($info, $settings) = @_;

  my $tsv;

  # First part of the spreadsheet is the head
  my $head = $$info{_head};
  while(my($key,$value) = each(%$head)){
    $tsv .= "$key\t$value\n";
  }
  $tsv .= "\n";

  my @strain = sort grep{!/^_/} keys(%$info);
  my @header = sort keys(%{ $$info{$strain[0]} });
  $tsv .= join("\t", @header)."\n";
  for my $strain(@strain){
    for my $h(@header){
      my $value = $$info{$strain}{$h} || "-";
      $tsv .= "$value\t";
    }
    $tsv .= "\n";
  }

  return $tsv;
}

sub updateChecksums{
  my($info, $settings) = @_;

  my %newInfo;
  my $dir = $$info{_dir};
  
  for my $key(sort grep{/^_/} keys(%$info)){
    # Capture the hash metadata (e.g., input spreadsheet)
    $newInfo{$key} = $$info{$key};
  }

  my @strain = sort grep{!/^_/} keys(%$info);
  for(my $i=0;$i<@strain;$i++){
    my $strain = $strain[$i];

    logmsg "Hashsums for $strain";
    # Copy the hash so that we aren't modifying in place
    my %s = %{ $$info{$strain} };
    if($s{SRArun_acc}){
      logmsg "  => SRArun_acc ($s{SRArun_acc})";
      $s{sha256sumRead1} = checksum("$dir/${strain}_1.fastq.gz", $settings);
      $s{sha256sumRead2} = checksum("$dir/${strain}_2.fastq.gz", $settings);
    }
    if($s{nucleotide}){
      logmsg "  => nucleotide ($s{nucleotide})";
      $s{sha256sumnucleotide} = checksum("$dir/$s{strain}.fna", $settings);
    }
    if($s{assembly}){
      logmsg "  => assembly ($s{assembly})";
      $s{sha256sumAssembly} = checksum("$dir/$s{strain}.fna", $settings);
    }

    $newInfo{$strain} = \%s;

    if($$settings{'stop-at'} && $i >= $$settings{'stop-at'}-1){
      logmsg "DEBUG: just taking ".($i+1)." samples";
      last;
    }
  }

  return \%newInfo;
    
}

sub readSpreadsheet{
  my($infile) = @_;

  my %info;
  $info{_in} = $infile;
  $info{_dir} = dirname($infile);

  my $is_header = 1; # whether we are reading the header
  my @header = (); # header fields in second half
  open(my $fh, $infile) or die "ERROR: could not read $infile: $!";
  while(<$fh>){
    chomp;
    next if(/^\s*$/);
    my @F = split(/\t/, $_);

    if(/biosample_acc/i && /strain/i){
      $is_header=0;
      @header = @F;
    }
    elsif($is_header){
      my($key, $value) = @F;
      $info{_head}{$key} = $value;
    }
    else{
      my %F = map{$header[$_] => $F[$_]} (0..@F-1);
      my $strain = $F{strain} or die "ERROR: could not find strain in this line ".Dumper \%F;
      $info{$F{strain}} = \%F;
    }
  }
  close $fh;

  return \%info;
}
    

# Checksum a file consistently across this script
sub checksum{
  my($file,$settings)=@_;
  my $sha=Digest::SHA->new("sha256");
  die "ERROR: could not checksum file $file because it doesn't exist!" if(!-e $file);
  $sha->addfile($file);
  return $sha->hexdigest;
}

sub usage{
  print "$0: reads a onedir layout output directory from GenFSGopher and adjusts the hashsums so that it passes QC
  Usage: $0 [options] genfsgohper.out/ > newdataset.tsv
  --stop-at  0  If set, will only read the first X samples.
                Useful for debugging.
";
  exit 0;
}

