#!/usr/bin/env python

## Jill Hagey
## CDC
## qpk9@cdc.gov
## https://github.com/jvhagey/
## 2021

## This script requires the selenium package which will need to have a driver installed see the following link:
# https://pypi.org/project/selenium/
## This driver will need to be added to your path following the following instructions:
# https://zwbetz.com/download-chromedriver-binary-and-add-to-your-path-for-automated-functional-testing/
# Or see alternative option on line 49

# importing packages
from numpy import *
import pandas as pd
from selenium import webdriver
from argparse import ArgumentParser


def parse_cmdline():
	"""Parse command-line arguments for script."""
	parser = ArgumentParser(prog="NCBI_Grabbing.py", description="""This script will take in and ID file and go scrap the information from the ncbi SRR site.""")
	parser.add_argument("-f", "--ID-file", dest="IDs", action="store", default=False, required=True, help="A full path to the mapping file that is tab delimited with at columns GISAID_ID and SRR_ID.")
	parser.add_argument("-p", "--pango-file", dest="pango", action="store", default=False, required=True, help="The full path to Pango_Random_Genomes_Stats.tsv file that came out of Generate_Random_Genomes.py.")
	args = parser.parse_args()
	return args

# set colors for warnings so they are seen
CRED = '\033[91m' + '\nWarning:'
CYEL = '\033[93m'
CEND = '\033[0m'

pd.set_option("max_columns", None)
pd.set_option("max_rows", None)

def NCBI_grab(IDs):
	""" This function goes to the ncbi website and clicks the download button to get a .csv file that has the path
	web address for each genome. """
	df = pd.DataFrame(columns = ["SRR", "BioSample", "Layout", "Instrument", "Primers", "Protocol"]) # creating empty dataframe for later
	count = 0
	Design = ""
	with open(IDs) as file:
		for SRR in file:
			driver = webdriver.Chrome()  # Alternatively you can change this to driver webdriver.Chrome(executable_path="C:\\chromedriver.exe")
			driver.get("https://www.ncbi.nlm.nih.gov/sra/") # get to gsaid login page
			driver.find_element_by_id("term").send_keys(SRR) # enter login info
			driver.find_element_by_id('search').click()
			BioSample = driver.find_element_by_xpath("//a[@title='Link to BioSample']").text
			BioSample = BioSample.replace("\n","")
			details = driver.find_element_by_xpath('//*[@id="ResultView"]/div[@class="expand showed sra-full-data"]/div').text
			lines = details.splitlines()
			Protocol = "Unknown"
			for line in lines:
				if line.startswith("Layout"):
					Layout = line.split(": ")[1]
				if line.startswith("Instrument"):
					Instrument = line.split(": ")[1]
				if line.startswith("Construction protocol"):
					Design = line.split(": ")[1]
					Design = line.replace("ILLUMINA_DNA_PREP|","")
					Design = Design.replace("Construction protocol: ", "")
			if Design == "" or any(substring in Design for substring in ["NEXTERA", "Nextera", "nextera"]):
				design_element = driver.find_element_by_xpath('//*[@id="ResultView"]/div[@class="sra-full-data"]').text
				design_lines = design_element.splitlines()
				for line in design_lines:
					if not line.startswith("Design"):
						design_element = driver.find_element_by_xpath('//*[@id="ResultView"]/div[5]').text
						design_lines = design_element.splitlines()
						for line in design_lines:
							if line.startswith("artic_primer_version"):
								Design = line.replace(":", "")
							if line.startswith("artic_protocol_version"):
								Protocol = line.replace(":", "")
					elif line.startswith("Design"):
						Design = line.replace("Design:", "")
					else:
						Design = "Unknown"
			count = count + 1
			print(CYEL + "Got info for {}, which is the {} sequence.".format(BioSample, count) + CEND)
			new_row = {'SRR': SRR, 'BioSample': BioSample, 'Layout': Layout, 'Instrument': Instrument, 'Primers': Design, 'Protocol': Protocol}
			print(new_row)
			df = df.append(new_row, ignore_index=True)
			driver.close
		print(CYEL+ "Retrieved information for {} SRRs".format(count) + CEND)
		#df.to_csv('NCBI_Info_Larger.csv', sep=',', index=False)
		return df

def clean_table(NCBI_Info_Larger):
	""" This function cleans the datatable to convert all possible versions encountered of saying Artic V3 primers. There are probably other cases of different ways this is input, but that is a manual process to identify along the way."""
	#NCBI_info = pd.read_csv('NCBI_Info_Larger.csv', sep=',', header=0)
	NCBI_info = NCBI_Info_Larger
	NCBI_info['SRR'] = NCBI_info['SRR'].str.replace("\n", "")
	NCBI_info['Primers'] = NCBI_info['Primers'].replace({' Whole genome sequencing of SARS-CoV-2 using the Artic protocol V3 and Illumina MiSeq':'Artic protocol V3',
	                                                     ' Whole genome sequencing of SARS-CoV-2 using the Artic protocol V3 and Oxford Nanopore GridION sequencing':'Artic protocol V3',
	                                                     ' Illumina NovaSeq 6000 amplicon sequencing. Samples prepared and sequenced by The Lighthouse Lab in Milton Keynes and Alex Alderton, Roberto Amato, Sonia Goncalves, Ewan Harrison, David K. Jackson, Ian Johnston, Dominic Kwiatkowski, Cordelia Langford, John Sillitoe on behalf of the Wellcome Sanger Institute COVID-19 Surveillance Team (http://www.sanger.ac.uk/covid-team)': 'Unknown',
	                                                     ' Illumina NovaSeq 6000 amplicon sequencing. Samples prepared and sequenced by Rob Howes, The Lighthouse Lab in Cambridge and Alex Alderton, Roberto Amato, Jeffrey Barrett, Sonia Goncalves, Ewan Harrison, David K. Jackson, Ian Johnston, Dominic Kwiatkowski, Cordelia Langford, John Sillitoe on behalf of the Wellcome Sanger Institute COVID-19 Surveillance Team (https://www.sanger.ac.uk/covid-team)': 'Unknown',
	                                                     ' Illumina NovaSeq 6000 amplicon sequencing. Samples prepared and sequenced by Harper VanSteenhouse, Yumi Kasai, David Gray, Carol Clugston, Anna Dominiczak and Alex Alderton, Roberto Amato, Jeffrey Barrett, Sonia Goncalves, Ewan Harrison, David K. Jackson, Ian Johnston, Dominic Kwiatkowski, Cordelia Langford, John Sillitoe on behalf of the Wellcome Sanger Institute COVID-19 Surveillance Team (https:// www.sanger.ac.uk/covid-team)': 'Unknown',
	                                                     ' Illumina NovaSeq 6000 amplicon sequencing. Samples prepared and sequenced by Jacquelyn Wynn, Mairead Hyland, The Lighthouse Lab in Alderley Park and Alex Alderton, Roberto Amato, Jeffrey Barrett, Sonia Goncalves, Ewan Harrison, David K. Jackson, Ian Johnston, Dominic Kwiatkowski, Cordelia Langford, John Sillitoe on behalf of the Wellcome Sanger Institute COVID-19 Surveillance Team (https://www.sanger.ac.uk/covid-team)': 'Unknown',
	                                                     ' Illumina NovaSeq 6000 amplicon sequencing. Samples prepared and sequenced by Randox Laboratories and Alex Alderton, Roberto Amato, Jeffrey Barrett, Sonia Goncalves, Ewan Harrison, David K. Jackson, Ian Johnston, Dominic Kwiatkowski, Cordelia Langford, John Sillitoe on behalf of the Wellcome Sanger Institute COVID-19 Surveillance Team (https://www.sanger.ac.uk/covid-team)': 'Unknown',
	                                                     ' Illumina NovaSeq 6000 amplicon sequencing. Samples prepared and sequenced by The Lighthouse Lab in Milton Keynes and Alex Alderton, Roberto Amato, Jeffrey Barrett, Sonia Goncalves, Ewan Harrison, David K. Jackson, Ian Johnston, Dominic Kwiatkowski, Cordelia Langford, John Sillitoe on behalf of the Wellcome Sanger Institute COVID-19 Surveillance Team (https://www.sanger.ac.uk/covid-team)': 'Unknown',
	                                                     ' ARTIC Protocol V3 Illumina DNA Flex library prep':'Artic protocol V3', ' ARTIC Protocol V3 - Illumina DNA Flex library prep': 'Artic protocol V3',
	                                                     ' ARTIC PCR - tiling of viral cDNA(V3), sequenced by Illumina MiSeq with DNA Flex library prep-kit.Only reads aligned to SARS-CoV-2 reference (NC_045512.2) retained.': 'Artic protocol V3',
	                                                     'artic_primer_version 3': 'Artic protocol V3', " SARS-CoV-2 Sequencing on Illumina MiSeq Using ARTIC Protocol": "Artic protocol V3",
	                                                     ' ARTIC V3 PCR-tiling of viral cDNA': 'Artic protocol V3',
	                                                     ' Artic protocol V3': 'Artic protocol V3',
	                                                     ' ILLUMINA_DNA_PREP | Artic_V3': 'Artic protocol V3',
	                                                     ' ARTIC v3 amplicons, NexteraXT library, minimap2 v2.17, ivar v1.2, samtools v1.10. Using minimap2, short reads mapped to SARS-CoV-2 NCBI accession MN908947.3. Using samtools, proper_pairs (samflag 2) mapping to MN908947.3 retained, unmapped reads (samflag 4) discarded (to filter out non-SARS-CoV-2 cDNA). Filtered reads submitted to NCBI':'Artic protocol V3',
	                                                     ' ARTIC V3 amplicons, Nextera XT library, minimap2 v2.17, ivar v1.2.1, samtools v1.10. Using minimap2, short reads mapped to SARS-CoV-2 NCBI accession MN908947.3. Using samtools, proper_pairs (samflag 2) mapping to MN908947.3 retained, unmapped reads (samflag 4) discarded (to filter out non-SARS-CoV-2 cDNA). Filtered reads submitted to NCBI' : 'Artic protocol V3',
	                                                     ' ARTIC v3, minimap2 v2.17, ivar v1.2.2, samtools v1.10. Using minimap2, short reads mapped to SARS-CoV-2 NCBI accession MN908947.3. Using samtools, proper_pairs (samflag 2) mapping to MN908947.3 retained, unmapped reads (samflag 4) discarded (to filter out non-SARS-CoV-2 cDNA). Filtered reads submitted to NCBI': 'Artic protocol V3',
	                                                     'Artic_V3': 'Artic protocol V3', " Total RNA from SARS-CoV-2 positive samples was converted to cDNA. Viral whole-genome amplification was performed according to the Artic Network protocol (https://artic.network/ncov-2019) using the SARS-CoV-2 primer scheme (V3).": 'Artic protocol V3'})
	#NCBI_info['Protocol'] = NCBI_info['Protocol'].replace({'artic_protocol_version 3.0': 'Artic protocol V3'})
	NCBI_info.loc[NCBI_info['Protocol'] == 'artic_protocol_version 3.0', 'Primers'] = 'Artic protocol V3'
	NCBI_info_cleaned = NCBI_info[NCBI_info["Primers"].str.contains('Artic protocol V3')]
	print(NCBI_info)
	#NCBI_info_cleaned.to_csv('NCBI_Info_Cleaned_Run2.csv', sep=',', index=True)
	return NCBI_info_cleaned
	
def combine(pango, NCBI_info_cleaned):
	#NCBI_info = pd.read_csv('NCBI_Info_Cleaned_Run2.csv', sep=',', header=0)
	NCBI_info = NCBI_info_cleaned
	Pango = pd.read_csv(pango, sep='\t', header=0)
	NCBI_info.rename(columns = {'SRR':'SRR_ID'}, inplace = True) # change column names for merging
	NCBI_info = NCBI_info.drop(columns=['Unnamed: 0'])
	NCBI_info['SRR_ID'] = NCBI_info['SRR_ID'].str.replace("\n", "")
	Combined = NCBI_info.merge(Pango, how='inner', on='SRR_ID')  # merge
	Combined.to_csv('Random_Genomes_With_NCBI_Info.csv', sep=',', index=True)

def double_check(SRR):
	driver = webdriver.Chrome()  # Alternatively you can change this to driver webdriver.Chrome(executable_path="C:\\chromedriver.exe")
	driver.get("https://www.ncbi.nlm.nih.gov/sra/")  # get to sra login page
	driver.find_element_by_id("term").send_keys(SRR) 
	driver.find_element_by_id('search').click()
	details = driver.find_element_by_xpath('//*[@id="ResultView"]/div[4]/span').text
	lines = details.splitlines()
	for line in lines:
		if line.startswith("Amplicon based sequencing"):
			Sample = line.replace("Amplicon based sequencing (ARTIC v3 Primers) of clinical SARS-CoV-2 virus", "Artic protocol V3")
	print(Sample)

def main():
	args = parse_cmdline()
	NCBI_Info_Larger = NCBI_grab(args.IDs)
	NCBI_info_cleaned = clean_table(NCBI_Info_Larger)
	combine(args.pango, NCBI_info_cleaned)
	#SRR = "SRR13530301"
	#double_check(SRR)

if __name__ == '__main__':
	main()
