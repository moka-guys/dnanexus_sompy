# dnanexus_sompy v1.1

## What does this app do?
This app uses the [som.py](https://github.com/Illumina/hap.py/blob/master/doc/sompy.md) module from the [hap.py](https://github.com/Illumina/hap.py) package from Illumina (v0.3.9 (Docker: https://hub.docker.com/r/pkrusche/hap.py/)). Two VCFs can be compared (e.g. a "truth" VCF against a query) and the recall reported. 

## What are typical use cases for this app?
To check that all expected variants have been called for commercial control samples such as HD200 run on cancer runs including Swift and TSO500.

## What inputs are required for this app to run?
Input files:
- a "truth" VCF (.vcf)
- a query VCF (.vcf) *- output from the workflow/variant caller being assessed. Note: an array of VCFs can be supplied but they should all use the same settings (i.e. not a mix of varscan and vardict VCFs). If analysing TSO500 VCFs a single VCF should be supplied.*


Parameters:
- Skip - default=true. Set to false to allow app to run. Allows app to be included in workflows but only run for relevant samples e.g. HD200.
- Varscan - default=false. If set to true an addition output csv file containing the list of variants assessed is produced. This is only available for certain variant callers, see [sompy docs](https://github.com/Illumina/hap.py/blob/master/doc/sompy.md)
- TSO500 - default=false. Set to true for a TSO500 input VCF. bcftools will be used to convert to the required input format for som.py.

## What does this app output?
This app outputs .csv and .json results files for each vcf assessed (saved in the QC folder). For varscan vcfs, if Varscan=true has been used an additional csv is generated with the list of variants.

## How does this app work?
1. input VCFs are downloaded
2. if required, a dockerised version of bcftools (v1.13) is used to convert the query VCF to the correct format
3. A dockerised version of hap.py is used, calling the som.py module
4. som.py compares the query VCF with the truth VCF, and returns recall (sensitivity) results
5. the output files are upload to the DNA Nexus project.

## What are the limitations of this app?
- Only summary statistics are produced for most VCFs. The list of variants with true positive/false positive (etc) information is only available for certain variant callers, e.g. Varscan
- This version of the app uses a GRCh37 reference genome only, so is not suitable for GRCh38.

### This app was produced by the Viapath Genome Informatics Team.