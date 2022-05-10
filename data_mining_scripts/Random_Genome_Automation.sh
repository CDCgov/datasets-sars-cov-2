#! /bin/bash -l
#
## -- begin embedded SGE options --
# save the standard output text to this file instead of the default jobID.o file
#$ -o /$PWD/Random_Genome_Automation/Run_2/Random_Genome_Automation_Stats.out
#
# save the standard error text to this file instead of the default jobID.e file
#$ -e /$PWD/Random_Genome_Automation/Run_2/Random_Genome_Automation_Stats.err
#
# Rename the job to be this string instead of the default which is the name of the script
#$ -N Random_Genome_Automation_Stats
# 
# Requesting shared memory across 10 cpus
#$ -pe smp 10
#
# Requesting 30G of Memory for the job
#$ -l h_vmem=30G
#
# Refer all file reference to work the current working directory which is the directory from which the script was qsubbed
#$ -cwd
#
#
## -- end embedded SGE options --


cd /$PWD/Random_Genome_Automation
## Getting sequence variants
module load seqkit/1.0
module load BBMap/38.90
module load snippy/4.3.8

#python3 Generate_Random_Fasta.py --random-only -n 50

python3 /$PWD/Random_Genome_Automation/Generate_Random_Fasta.py --all -f /$PWD/B.1.617/413.B.1.617.fasta -m /$PWD/B.1.617/mapping_file.txt -ref /$PWD/B.1.617/Analysis/Reference_Sequences -p Delta_Variants_pango2_lineage.csv
