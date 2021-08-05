#!/usr/bin/env perl

# Downloads a test set directory
# 
# Author: Lee Katz <gzu2@cdc.gov>
# WGS standards and analysis group of the Gen-FS collaboration

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use File::Basename qw/fileparse dirname basename/;
use File::Temp qw/tempdir tempfile/;
use File::Spec;

my $VERSION=0.5;

my $scriptInvocation="$0 ".join(" ",@ARGV);
my $scriptsDir=dirname(File::Spec->rel2abs($0));
local $0=basename $0;
sub logmsg{print STDERR "$0: @_\n";}

exit main();

sub main{
  my $settings={run=>1};
  GetOptions($settings,qw(tempdir=s help outdir=s format=s shuffled! layout=s numcpus=i run! version citation));
  die usage() if($$settings{help});
  $$settings{format}||="tsv"; # by default, input format is tsv
  $$settings{seqIdTemplate}||='@$ac_$sn[_$rn]/$ri';
  $$settings{layout}||="onedir";
  $$settings{layout}=lc($$settings{layout});
  $$settings{numcpus}||=1;
  $$settings{'calculate-hashsums'}||=0; # whether to recalculate hashsums and ignore warnings

  #  If the user wants to recalculate hashsums, then
  #  set the hashsum option on and the layout will be onedir.
  if($$settings{layout} =~ /^hashsum/i){
    $$settings{layout} = "onedir";
    $$settings{'calculate-hashsums'}=1;
  }

  if($$settings{version}){
    print "$0 $VERSION\n";
    return 0;
  }
  if($$settings{citation}){
    print "Please reference the WGS Standards and Analysis working group, part of the Gen-FS collaboration
    https://github.com/WGS-standards-and-analysis/datasets
    https://peerj.com/preprints/3107/

    For individual datasets, please contact the source listed the dataset spreadsheet.\n";
    return 0;
  }

  # Get the output directory and spreadsheet, and make sure they exist
  $$settings{outdir}||=die "ERROR: need outdir parameter\n".usage();
  mkdir $$settings{outdir} if(!-d $$settings{outdir});
  my $spreadsheet=$ARGV[0] || die "ERROR: need spreadsheet file!\n".usage();
  die "ERROR: cannot find $spreadsheet" if(!-e $spreadsheet);

  # Read the spreadsheet, keeping in mind which format
  my $infoTsv = {};
  if($$settings{format} eq 'tsv'){
    $infoTsv=tsvToMakeHash($spreadsheet,$settings);
  } else {
    die "ERROR: I do not understand format $$settings{format}";
  }

  my $makefile=writeMakefile($$settings{outdir},$infoTsv,$settings);
  runMakefile($$settings{outdir},$settings);

  return 0;
}

sub tsvToMakeHash{
  my($tsv,$settings)=@_;

  # Thanks Torsten Seemann for this idea
  my $make_target = '$@';
  my $make_dep = '$<';
  my $make_deps = '$^';
  my $bash_dollar = '$$';

  # For the fastq-dump command
  my $seqIdTemplate=$$settings{seqIdTemplate};
     $seqIdTemplate=~s/\$/\$\$/g;  # compatibility with make
  
  # Initialize a make hash
  my $make={};
  # TODO rm -f $make_target.tmp and pipe all hashsum contents to $make_target.tmp.
  # TODO last step of sha256sum.txt, mv -v $make_target.tmp to $make_target.
  $$make{"sha256sum.txt"}{CMD}=["rm -f $make_target"];
  $$make{"all"}={
    CMD=>[
      '@echo "DONE! If you used this script in a publication, please cite us at github.com/WGS-standards-and-analysis/datasets"',
    ],
    DEP=>[
      "tree.dnd",
      "sha256sum.txt",
    ],
  };
  $$make{".PHONY"}{DEP}=['all'];
  $$make{".DEFAULT"}{DEP}=['all'];
  $$make{".DEFAULT"}{".DELETE_ON_ERROR"}=[];
  $$make{".DEFAULT"}{".SUFFIXES"}=[];

  # We will append SRA Run IDs to the zeroth element
  # for this command like so:
  #   $$make{"prefetch.done"}{CMD}[0] .= " $SRA_Run_ID";
  $$make{"prefetch.done"}{CMD} = [
    "prefetch",
    "touch $make_target",
  ];

  my $fileToName={};            # mapping filename to base name
  my $have_reached_biosample=0; # marked true when it starts reading entries
  my @header=();                # defined when we get to the biosample_acc header row
  open(TSV,$tsv) or die "ERROR: could not open $tsv: $!";
  while(<TSV>){
    s/^\s+|\s+$//g; # trim whitespace
    next if(/^$/);  # skip blank lines

    ## read the contents
    # Read biosample rows
    if($have_reached_biosample){
      my $tmpdir = $$settings{tempdir} || tempdir("$0XXXXXX",TMPDIR=>1,CLEANUP=>1);

      my @F=split(/\t/,$_);
      for(@F){
        next if(!$_);
        s/^['"]+|['"]+//g;  # trim quotes
        s/^\s+|\s+$//g;     # trim whitespace
      }
      # Get an index of each column
      my %F;
      @F{@header}=@F;

      # SRA download command
      if($F{srarun_acc} && $F{srarun_acc} !~ /\-|NA/i){
        # Any error checking before we start with this entry.
        $F{strain} || die "ERROR: $F{srarun_acc} does not have a strain name!";

        my $filename1="$F{strain}_1.fastq.gz";
        my $filename2="$F{strain}_2.fastq.gz";
        my $dumpdir='.';

        if($$settings{layout} eq 'onedir'){
          # The defaults are set up for onedir, so change nothing if the layout is onedir
        } elsif($$settings{layout} eq 'byrun'){
          $dumpdir=$F{strain};
        } elsif($$settings{layout} eq 'byformat'){
          $dumpdir="reads";
        } elsif($$settings{layout} eq 'cfsan'){
          $dumpdir="samples/$F{strain}";
        } else{
          die "ERROR: I do not understand layout $$settings{layout}";
        }

        # Change the directory for these filenames if they aren't being
        # dumped into the working directory.
        if($$settings{layout} ne 'onedir'){
          $filename1="$dumpdir/$filename1";
          $filename2="$dumpdir/$filename2";
          $$make{$dumpdir}{CMD}=["mkdir -p $make_target"];
        }

        $$make{$filename2}={
          DEP=>[
            $dumpdir, $filename1,
          ],
          CMD=>[
            "mv $dumpdir/$F{srarun_acc}_2.fastq.gz '$make_target' || touch '$make_target'",
          ],
        };
        $$make{$filename1}={
          CMD=>[
            "\@echo Downloading $make_target $F{srarun_acc}",
            "fastq-dump --defline-seq '$seqIdTemplate' --defline-qual '+' --split-files -O $dumpdir --gzip $F{srarun_acc} ",
            "mv $dumpdir/$F{srarun_acc}_1.fastq.gz '$make_target'",
          ],
          DEP=>[
            $dumpdir,
            "prefetch.done",
          ],
        };
        push(@{ $$make{"all"}{DEP} }, $filename1, $filename2);

        $$make{"prefetch.done"}{CMD}[0] .= " $F{srarun_acc}";

        if($$settings{shuffled}){
          my $filename3="$dumpdir/$F{strain}.shuffled.fastq.gz";
          $$make{$filename3}={
            CMD=>[
              "run_assembly_shuffleReads.pl $filename1 $filename2 | gzip -c > $make_target",
              #"rm -v $make_deps",
            ],
            DEP=>[
              $filename1, $filename2
            ]
          };
          push(@{ $$make{"all"}{DEP} }, $filename3);
        }

        # Checksums, if they exist and if we're not recalculating
        if($F{sha256sumread1} && $F{sha256sumread1} !~ /\-|NA/ && !$$settings{'calculate-hashsums'}){
          push(@{ $$make{"sha256sum.txt"}{CMD} }, "echo \"$F{sha256sumread1}  $filename1\" >> $make_target");
          push(@{ $$make{"sha256sum.txt"}{DEP} }, $filename1);
        } 

        if($F{sha256sumread2} && $F{sha256sumread2} !~ /\-|NA/ && !$$settings{'calculate-hashsums'}){
          push(@{ $$make{"sha256sum.txt"}{CMD} }, "echo \"$F{sha256sumread2}  $filename2\" >> $make_target");
          push(@{ $$make{"sha256sum.txt"}{DEP} }, $filename2);
        }

        # If we are requesting checksums, calculate them.
        if ($$settings{'calculate-hashsums'}) {
          push(@{ $$make{"sha256sum.txt"}{CMD} }, 
            "sha256sum $filename1 >> $make_target",
            "sha256sum $filename2 >> $make_target",
          );
          push(@{ $$make{"sha256sum.txt"}{DEP} }, $filename1);
          push(@{ $$make{"sha256sum.txt"}{DEP} }, $filename2);
        }
      }

      # GenBank download command
      if($F{genbankassembly} && $F{genbankassembly} !~ /\-|NA/i){
        # Any error checking before we start with this entry.
        $F{strain} || die "ERROR: $F{genbankassembly} does not have a strain name!";

        my $filename1="$F{strain}.gbk";
        my $filename2="$F{strain}.fasta";
        my $dumpdir  ='.';

        if($$settings{layout} eq 'onedir'){
          # The defaults are set up for onedir, so change nothing if the layout is onedir
        } elsif($$settings{layout} eq 'byrun'){
          $dumpdir=$F{strain};
        } elsif($$settings{layout} eq 'byformat'){
          $dumpdir="genbank";
        } elsif($$settings{layout} eq 'cfsan'){
          # Only the reference genome belongs in this folder
          if($F{suggestedreference} =~ /^(true|1)$/i){
            $dumpdir="reference";
          } else {
            $dumpdir="samples/$F{strain}";
          }
        } else{
          die "ERROR: I do not understand layout $$settings{layout}";
        }

        # Change the directory for these filenames if they aren't being
        # dumped into the working directory.
        if($$settings{layout} ne 'onedir'){
          $filename1="$dumpdir/$filename1";
          $filename2="$dumpdir/$filename2";
          $$make{$dumpdir}{CMD}=["mkdir -p $dumpdir"];
        }

        $$make{$filename2}={
          CMD=>[
            #"\@echo running gbk2fas.sed to create $make_target",
            #"gbk2fas.sed $filename1 > $make_target",
            "esearch -db assembly -query '$F{genbankassembly} NOT refseq[filter]' | elink -target nuccore -name assembly_nuccore_insdc | efetch -format fasta > $make_target",
          ],
          DEP=>[
            $dumpdir, $filename1
          ]
        };
        push(@{ $$make{"all"}{DEP} }, $filename2);
        $$make{$filename1}={
          CMD=>[
            "esearch -db assembly -query '$F{genbankassembly} NOT refseq[filter]' | elink -target nuccore -name assembly_nuccore_insdc | efetch -format gbwithparts > $make_target",
          ],
          DEP=>[
            $dumpdir,
          ]
        };

        # Calculate hashsums if they exist and if we are not recalculating them
        if($F{sha256sumassembly} && $F{sha256sumassembly} !~ /\-|NA/ && !$$settings{'calculate-hashsums'}){
          push(@{ $$make{"sha256sum.txt"}{CMD} }, "echo \"$F{sha256sumassembly}  $filename1\" >> $make_target");
          push(@{ $$make{"sha256sum.txt"}{DEP} }, $filename1);
        }

        if ($$settings{'calculate-hashsums'}) {
          push(@{ $$make{"sha256sum.txt"}{CMD} }, 
            "sha256sum $filename1 >> $make_target",
          );
          push(@{ $$make{"sha256sum.txt"}{DEP} }, $filename1);
        }
      }

      # Sometimes there might only be a nucleotide accession
      # and not an assembly accession. This is under the 
      # nucleotide header.
      if($F{nucleotide} && $F{nucleotide} !~ /\-|NA/i){
        # Any error checking before we start with this entry.
        $F{strain} || die "ERROR: $F{nucleotide} does not have a strain name!";

        my $filename="$F{strain}.fna";
        my $dumpdir  ='.';

        if($$settings{layout} eq 'onedir'){
          # The defaults are set up for onedir, so change nothing if the layout is onedir
        } elsif($$settings{layout} eq 'byrun'){
          $dumpdir=$F{strain};
        } elsif($$settings{layout} eq 'byformat'){
          $dumpdir="nucleotide";
        } elsif($$settings{layout} eq 'cfsan'){
          # Only the reference genome belongs in this folder
          if($F{suggestedreference} =~ /^(true|1)$/i){
            $dumpdir="reference";
          } else {
            $dumpdir="samples/$F{strain}";
          }
        } else{
          die "ERROR: I do not understand layout $$settings{layout}";
        }

        # Change the directory for these filenames if they aren't being
        # dumped into the working directory.
        if($$settings{layout} ne 'onedir'){
          $filename="$dumpdir/$filename";
          $$make{$dumpdir}{CMD}=["mkdir -p $dumpdir"];
        }

        # The make command
        $$make{$filename}={
          CMD=>[
            "esearch -db nucleotide -query '$F{nucleotide}' | efetch -format fasta > $make_target", 
          ],
          DEP=>[
            $dumpdir
          ],
        };
        
        # Calculate hashsums if they exist and if we are not recalculating them
        if($F{sha256sumnucleotide} && $F{sha256sumnucleotide} !~ /\-|NA/ && !$$settings{'calculate-hashsums'}){
          push(@{ $$make{"sha256sum.txt"}{CMD} }, "echo \"$F{sha256sumnucleotide}  $filename\" >> $make_target");
          push(@{ $$make{"sha256sum.txt"}{DEP} }, $filename);
        }

        if ($$settings{'calculate-hashsums'}) {
          push(@{ $$make{"sha256sum.txt"}{CMD} }, 
            "sha256sum $filename >> $make_target",
          );
          push(@{ $$make{"sha256sum.txt"}{DEP} }, $filename);
        }
      }

    } 
    # If we got up to this line, it clues us in that we
    # have reached the meat of the spreadsheet.
    # Get the header.
    elsif(/^biosample_acc/){
      $have_reached_biosample=1;
      @header=split(/\t/,lc($_));
      next;
    }
    # metadata
    else {
      my ($key,$value)=split /\t/;
      $key=lc($key);
      $value||="";            # in case of blank values
      $value=~s/^\s+|\s+$//g; # trim whitespace
      $value=~s/\s+/_/g;      # turn whitespace into underscores
      #$$d{$key}=$value;
      #
      if($key eq 'tree'){
        $$make{"tree.dnd"}={
          CMD=>[
            "wget -O $make_target '$value'",
          ],
        };
        if($value eq "" || $value eq "-"){
          $$make{"tree.dnd"}{CMD}=["echo 'No tree was supplied'"];
        }
      }
    }

  }
  close TSV;

  # Last of the make target(s)
  if(!$$settings{'calculate-hashsums'}){
    push(@{ $$make{"sha256sum.txt"}{CMD} }, "sha256sum -c $make_target");
  }

  return $make;
}

# Thanks Torsten Seemann for the makefile idea
sub writeMakefile{
  my($outdir,$m,$settings)=@_;

  my $makefile="$outdir/Makefile";

  # Custom sort for how the entries are listed, in case I want
  # to change it later.
  my @target=sort{
    return -1 if ($a eq 'all');
    #return 1 if($a=~/(^\.)|all/ && $b !~/(^\.)|all/);
    return $a cmp $b;
  } keys(%$m);

  open(MAKEFILE,">",$makefile) or die "ERROR: could not open $makefile for writing: $!";
  print MAKEFILE "SHELL := /bin/bash\n";
  print MAKEFILE "MAKEFLAGS += --no-builtin-rules\n";
  print MAKEFILE "MAKEFLAGS += --no-builtin-variables\n";
  print MAKEFILE "export PATH := $scriptsDir:\$(PATH)\n";
  print MAKEFILE "\n";
  for my $target(@target){
    my $properties=$$m{$target};
    $$properties{CMD}||=[];
    $$properties{DEP}||=[];
    $$properties{DEP} = [grep {!/^\.$/} @{ $$properties{DEP} }];    # remove CWD from any dependency list
    print MAKEFILE "$target: ".join(" ",@{$$properties{DEP}})."\n";
    for my $cmd(@{ $$properties{CMD} }){
      print MAKEFILE "\t$cmd\n";
    }
    print MAKEFILE "\n";
  }

  return $makefile;
}

sub runMakefile{
  my($dir,$settings)=@_;
  my $command="nice make all --directory=$dir --jobs=$$settings{numcpus}";
  if($$settings{run}){
    system("$command 2>&1");
    if($?){
      logmsg "ERROR: `make` failed.  Please address all errors and then run the make command again:\n  $command";
      die;
    }
  } else {
    logmsg "User has specified --norun; to finish running this script, use a make command like so:
      $command";
  }

  # Notify the user about where hashsums are.
  if($$settings{'calculate-hashsums'}){
    logmsg "Hashsums will be calculated and recorded into sha256sum.txt. Remember to insert these new values into your spreadsheet.";
  }

  return 1;
}

sub usage{
  "  $0: Reads a standard dataset spreadsheet and downloads its data

  Usage: $0 -o outdir spreadsheet.dataset.tsv
  PARAM        DEFAULT  DESCRIPTION
  --outdir     <req'd>  The output directory
  --format     tsv      The input format. Default: tsv. No other format
                        is accepted at this time.
  --layout     onedir   onedir   - Everything goes into one directory
                        hashsums - Like 'onedir', but will recalculate hashsums
                                   and will ignore hashsum warnings.
                        byrun    - Each genome run gets its separate directory
                        byformat - Fastq files to one dir, assembly to another, etc
                        cfsan    - Reference and samples in separate directories with
                                   each sample in a separate subdirectory
  --shuffled   <NONE>   Output the reads as interleaved instead of individual
                        forward and reverse files.
  --norun      <NONE>   Do not run anything; just create a Makefile.
  --numcpus    1        How many jobs to run at once. Be careful of disk I/O.
  --citation            Print the recommended citation for this script and exit
  --version             Print the version and exit
  --tempdir    ''       Choose a different temp directory than the system default
  --help                Print the usage statement and die
  "
}


