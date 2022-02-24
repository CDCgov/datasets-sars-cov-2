# Contributing

Hi, thank you for taking the time to read this document.
We love contributions from the community and would like to guide you on how best to contribute.

## Creating a spreadsheet

The spreadsheet format has two major parts: the header and the body.
The header describes the whole dataset including the organism and the source of the dataset.
The body describes individual samples.

We have detailed the full specification in [SPECIFICATION.md](SPECIFICATION.md).

## Quality check (QC)

To accept the dataset, it must pass limited QC.
These are our suggested thresholds per sample.

* average phred score > 25
* mean depth per nucleotide > 10x
* number of nucelotides with depth lower than 10x is < 3000bp
* assembly total length > 49400
* ambiguous nucleotides < 10%
* assembly mean coverage > 25x
* percent reads mapped to the Wuhan reference genome > 65%
* VADR alert number <= 1

There are exceptions to these thresholds such as a "failed QC" dataset and so this is not automatically checked.

## Contribute a dataset

To submit a dataset, you must send us a pull request through GitHub.
Please include a note about what the dataset is, who you are, and whether the samples pass the QC thresholds above.

The dataset will be tested automatically on whether or not it can be used through GitHub Actions.
Therefore, all accessions must be public.

If there are any questions or comments, please submit a GitHub issue ticket before sending a pull request
so that we can discuss it further.

