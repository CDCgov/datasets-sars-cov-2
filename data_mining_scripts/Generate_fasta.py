#!/usr/bin/env python

## Jill Hagey
## CDC
## qpk9@cdc.gov
## https://github.com/jvhagey/
## 2021
## written in python3

from numpy import *
import os, re, glob, shutil
import pandas as pd
from argparse import ArgumentParser
import subprocess

# set colors for warnings so they are seen
CRED = '\033[91m' + '\nWarning:'
CYEL = '\033[93m'
CEND = '\033[0m'

#Before running you need to load the modules
#module load seqkit/1.0
#module load BBMap/38.90
#module load snippy/4.3.8

pd.set_option("max_columns", 50)
pd.set_option("max_rows", 50)


def parse_cmdline():
	"""Parse command-line arguments for script."""
	parser = ArgumentParser(prog="Generate_Random_Fasta.py", description="""This script will get 30 random genomes for wach VOC/VOI, run snippy on each sequence and generate a csv file with the information merged at the end. The following VOCs/VOIs are used: B.1.1.7, B.1.351, B.1.427, B.1.429, P.1, B.1.526, B.1.525, B.1.526.1,P.2.
	This script expectsb a pangolin report like XXXXX.pangolin_report.csv and SrrGisMapping.tsv are in the same directory as this script.""")
	parser.add_argument("-p", "--pandolin-report", dest="pangolin_input", action="store", default=False, required=True, help="Pass the pangolin report file.")
	parser.add_argument("-f", "--fasta", dest="full_fasta", action="store", default=False, required=True, help="Pass a fasta file with all sequences of variants to be split.")
	parser.add_argument("-v", "--variants", dest="variants", action="store", default=False, required=False, help="A file with one variant on each line, will be converted to a list.")
	parser.add_argument("-r", "--random-only", dest="random_only", action="store_true", default=False, required=False, help="This flag will just rerun picking random sequences. This bypasses the creation of the .txt or .fasta files.")
	parser.add_argument("-n", "--seq-num", dest="seq_num", action="store", default=30, required=False, help="The number of random sequences to pull for each VOC/VOIs.")
	parser.add_argument("-a", "--all", dest="all_samples", action="store_true", default=False, required=False, help="This flag just runs everything rather than picking random samples.")
	parser.add_argument("-ref", "--ref-path", dest="ref_path", action="store", default=False, required=True, help="Full path for where reference sequences are found.")
	parser.add_argument("-m", "--srr-to-gisaid-map", dest="mapping_file", action="store", default=False, required=True, help="Full path for where a mapping file can be found. Should be tab separated with at least the following columns GISAID_ID and SRR_ID.")
	args = parser.parse_args()
	return args

def get_file(variants, ref_path, pangolin_input, all_samples, seq_num, random_only, full_fasta):
	"""For each variant do the following."""
	#VOC_VOI_list = ["B.1.1.7", "B.1.351", "B.1.427", "B.1.429", "P.1", "B.1.526", "B.1.525", "B.1.526.1" ,"P.2"]# list of VOIs/VOCs
	#VOC_VOI_list = ["B.1.617.1", "B.1.617.2", "B.1.617.3"]# list of VOIs/VOCs
	with open(variants) as f:
		VOC_VOI_list = [line.rstrip() for line in f]
	df = pd.DataFrame(columns = ["taxon", "lineage", "probability", "pangoLEARN_version", "status", "note", "ID", "LENGTH", "ALIGNED", "UNALIGNED", "VARIANT", "HET", "MASKED", "LOWCOV"]) # creating empty dataframe for later
	Pango_Output = pd.read_csv(pangolin_input, sep=',', header=0)  # open file
	Pango_Output_VOCI = Pango_Output[Pango_Output['lineage'].isin(VOC_VOI_list)] # reduce dataframe to only VOC/VOI for faster compute. This removes ~20K rows
	if random_only == False and all_samples == False:
		count = 0 # to make sure we create our dataframe right
		for variant in VOC_VOI_list: # Loop through VOCs/VOIs in list
			Variant_df = Pango_Output_VOCI[Pango_Output_VOCI['lineage']==variant] # get dataframe with only one VOC/VOI
			num_seq = shape(Variant_df)[0] # get number of total sequences for VOC/VOI
			variant_fasta = variant + ".fasta"
			variant_headers = generate_header_file(variant, Variant_df) # get headers for filtering
			print(CYEL + "There are {} sequences for the variant {}. The sequence IDs were printed to {}.\n".format(num_seq, variant, variant_headers) + CEND)
			seqkit_version = generate_fasta(variant_headers, variant_fasta, full_fasta) # generate fasta by filtering using headers file
			print(CYEL + "Finished running Seqkit on variants.\n" + CEND)
			variant_random_fasta, bbmap_version = random_sampling_variant_fasta(seq_num, variant, variant_fasta)
			generate_input_file(variant, variant_random_fasta) # This generats the .tab input file for snippy to run on each sequence.
			snippy_version = run_snippy(ref_path, variant, variant_fasta) # Run snippy on each sample
			if count == 0:
				df_merge = combine_output(variant, Pango_Output_VOCI, df)
				count = count + 1
			else:
				df_merge = combine_output(variant, Pango_Output_VOCI, df_merge)
		df_merge.to_csv('Pango_Random_Genomes.csv', sep='\t', index=False)
		print(CYEL + "This pipeline was run with {},{} and {}.\n".format(seqkit_version, bbmap_version, snippy_version) + CEND)
	if random_only == True:
		count = 0
		for variant in VOC_VOI_list:
			variant_fasta = variant + ".fasta"
			variant_random_fasta, bbmap_version = random_sampling_variant_fasta(seq_num, variant, variant_fasta)
			generate_input_file(variant, variant_random_fasta)
			snippy_version = run_snippy(ref_path, variant, variant_fasta)
			if count == 0:
				df_merge = combine_output(variant, Pango_Output_VOCI, df)
				count = count + 1
			else:
				df_merge = combine_output(variant, Pango_Output_VOCI, df_merge)
		df_merge.to_csv('Pango_Random_Genomes.csv', sep='\t', index=False)
		#print(CYEL + "This pipeline was run with {} and {}.\n".format(snippy_version, bbmap_version) + CEND)
	if all_samples == True:
		count = 0
		for variant in VOC_VOI_list:
			clean_up(variant)
			Variant_df = Pango_Output_VOCI[Pango_Output_VOCI['lineage']==variant] # get dataframe with only one VOC/VOI
			num_seq = shape(Variant_df)[0] # get number of total sequences for VOC/VOI
			variant_fasta = variant + ".fasta"
			variant_headers = generate_header_file(variant, Variant_df) # get headers for filtering
			print(CYEL + "There are {} sequences for the variant {}. The sequence IDs were printed to {}.\n".format(num_seq, variant, variant_headers) + CEND)
			seqkit_version = generate_fasta(variant_headers, variant_fasta, full_fasta) # generate fasta by filtering using headers file
			print(CYEL + "Finished running Seqkit on variants.\n" + CEND)
			generate_input_file(variant, variant_fasta)
			snippy_version = run_snippy(ref_path, variant, variant_fasta)
			if count == 0:
				df_merge = combine_output(variant, Pango_Output_VOCI, df)
				count = count + 1
			else:
				df_merge = combine_output(variant, Pango_Output_VOCI, df_merge)
		df_merge.to_csv('Pango_Random_Genomes.csv', sep='\t', index=False)
		return df_merge

def generate_header_file(variant, Variant_df):
	"""Generates a txt file that contains sequence headers that will be used to filter sequences."""
	variant_headers = variant + ".txt"
	with open(variant_headers, "w", newline='\n') as file:
		Variant_df.taxon.to_csv(file, index=False, header=False, line_terminator='\n')
	# In GISAID, Northern_Ireland is missing its underscore so we have to adjust our file to reflect this.
	with open(variant_headers, "r") as file:
		filedata = file.read()
		filedata = filedata.replace('Northern_Ireland', 'Northern Ireland')
	with open(variant_headers, 'w', newline='\n') as file:
		file.write(filedata)
	return variant_headers

def generate_fasta(variant_headers, variant_fasta, full_fasta):
	"""Generates a fasta file by filtering with seqkit for headers we want in the variant_headers file."""
	seqkit_version = "seqkit 1.0"
	subprocess.call("seqkit grep -n -f " + str(variant_headers) + " " + full_fasta + " > " + str(variant_fasta), shell=True)
	return seqkit_version

def random_sampling_variant_fasta(seq_num, variant, variant_fasta):
	"""Generates a fasta file with random sampling from the full fasta file."""
	clean_up(variant)
	variant_random_fasta = variant + "_"+ seq_num +"RandomGenomes.fasta"
	bbmap_version = "BBMap/38.90"
	subprocess.call("reformat.sh in=" + str(variant_fasta) + " out=" + str(variant_random_fasta) + " samplereadstarget="+ seq_num, shell=True)
	return variant_random_fasta, bbmap_version

def clean_up(variant):
	'''Deletes old version of files and directory so it doesn't keep appending in the generate_input_file function.'''
	try:
		os.remove(variant + ".tab")
	except OSError as e:
		pass
	try:
		os.remove(variant + "_30RandomGenomes.fasta")
	except OSError as e:
		pass
	try:
		os.remove(variant + ".fasta")
	except OSError as e:
		pass
	try:
		os.remove(variant + ".txt")
	except OSError as e:
		pass
	try:
		shutil.rmtree(variant) # deletes directory and all its contents.
	except OSError as e:
		pass

def generate_input_file(variant, file ):
	'''Generates a input file as an input for snippy'''
	os.mkdir(variant) # create directory for each variant
	os.chdir(variant) # got into directory
	subprocess.call("awk -F '|' '/^>/ {F=sprintf(\"%s.fasta\",$2); print > F;next;} {print >> F;}' < ../" + str(file), shell=True) # split fasta into individual files in new directory
	split_files = glob.glob('*.fasta')  # grabbing all new fasta files to loop through
	snippy_input_file = variant + ".tab"  # create snippy input file name
	for split_file in split_files: # loop through split files
		split_file_name = split_file.replace(".fasta","") # get GSAID ID name
		full_file_path = os.path.normpath(os.getcwd() + os.sep + os.pardir) + "/" + variant + "/" + split_file
		line = split_file_name + "\t" + full_file_path + "\n"
		with open(snippy_input_file, "a") as f:
			f.write(line)
	os.chdir("../")

def run_snippy(ref_path, variant, variant_fasta):
	'''Runs Snippy on each VOC/VOI '''
	os.chdir(variant)
	snippy_version = "snippy 4.3.8"
	snippy_input_file = variant  + ".tab"
	reference_path = ref_path + "/" + variant_fasta
	with open('runme.sh','w+') as runme:
		subprocess.call("snippy-multi " + str(snippy_input_file) + " --ref " + str(reference_path) + " --cpus 16", shell=True, stdout=runme)
	subprocess.call("sh runme.sh", shell=True)
	os.chdir("../")
	return snippy_version

def combine_output(variant, Pango_Output_VOCI, df):
	'''Combining output into one dataframe as we loop through each VOC/VOI'''
	Snippy_Output = pd.read_csv(variant + '/core.txt', sep='\t', header=0) # open file from snippy
	seq_list = Snippy_Output['ID'].tolist()
	Pango_Output_VOCI["ID"] = Pango_Output_VOCI.taxon.str.split("|").str[1]
	Pango_30_df = Pango_Output_VOCI[Pango_Output_VOCI['ID'].isin(seq_list)] # reduce dataframe to sequences that were run through snippy
	Combined = Pango_30_df.merge(Snippy_Output, how='inner', on='ID')
	Combined = Combined.sort_values(["VARIANT", "LOWCOV"])
	df_merge = df.append(Combined, ignore_index=True)
	return df_merge

def Check_and_add_stats(df_merge):
	SRR_Checked = ID_check(df_merge)
	df_cal_stats = cal_stats(SRR_Checked)
	df_cal_stats.to_csv('Pango_Random_Genomes_Stats.tsv', sep='\t', index=False)

def ID_check(mapping_file):
	'''Removes duplicate SRR and GISAID_IDs from dataset.'''
	df = pd.read_csv('Pango_Random_Genomes.csv', sep='\t', header=0)
	rom_num = df.shape[0]
	df = df.drop_duplicates('ID') # drop rows with duplicate GISAID_IDs
	print(CYEL + "There were {} rows that had duplicate GSAID IDs.".format((rom_num - df.shape[0])) + CEND)
	df.rename(columns = {'ID':'GISAID_ID'}, inplace = True) # change column names for merging
	df_SRR = pd.read_csv(mapping_file, sep='\t', header=0)
	SRR_Check = df.merge(df_SRR, how='inner', on='GISAID_ID') # merge 
	SRR_Checked = SRR_Check.drop_duplicates('SRR_ID') # drop rows with duplicate SRRs
	print(CYEL + "There were {} rows that had duplicate SRR IDs.".format((SRR_Check.shape[0] - SRR_Checked.shape[0])) + CEND)
	return SRR_Checked

def cal_stats(SRR_Checked):
	'''Calculates Range and Average for SNPs and Low Coverage Regions'''
	col_list = ["VARIANT", "LOWCOV"]
	for col in col_list:
		SRR_Checked[col] = pd.to_numeric(SRR_Checked[col]) # make column numeric
		df = SRR_Checked.groupby('lineage', as_index=False)[col].mean().round(2)
		Variant_Min = SRR_Checked.groupby('lineage', as_index=False)[col].min().astype(str)
		Variant_Max = SRR_Checked.groupby('lineage', as_index=False)[col].max().astype(str)
		Variant_Max["Range"] = Variant_Min[col] + "-" + Variant_Max[col]
		Variant_Range = Variant_Max.drop(columns=[col])
		df = df.merge(Variant_Range, how='inner', on='lineage') # merge 
		Mean = col +"_mean"
		Range = col +"_Range"
		df.rename(columns = {col:Mean, 'Range':Range}, inplace = True) # change column names for merging
		SRR_Checked = SRR_Checked.merge(df, how='inner', on='lineage') # merge 
	return SRR_Checked

def main():
	args = parse_cmdline()
	df_merge = get_file(args.variants, args.ref_path, args.pangolin_input, args.all_samples, args.seq_num, args.random_only, args.full_fasta)
	Check_and_add_stats(args.mapping_file,df_merge)

if __name__ == '__main__':
	main()
