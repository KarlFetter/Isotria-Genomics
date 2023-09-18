# Kmer Based Genomic Methods

## Quality Control

<details>
<summary>QC the raw reads wih fastqc and multqc</summary>

```
echo `hostname`

#################################################################
# FASTQC of raw reads 
#################################################################
# create an output directory to hold fastqc output
DIR="raw"
mkdir -p ${DIR}_fastqc
readDir=/core/projects/EBP/conservation/isotria/kmer_methods/01_raw_reads/GenomeKmer_Orchid_Sept2023


module load fastqc/0.11.7

readpair=Fetter_Orchid_lysed_S449_L003
fastqc --threads 4 --outdir ./${DIR}_fastqc/ $readDir/${readpair}_R1_001.fastq.gz $readDir/${readpair}_R2_001.fastq.gz

#################################################################
# MULTIQC of raw reads 
#################################################################
module load MultiQC/1.9

mkdir -p ${DIR}_multiqc
multiqc --outdir ${DIR}_multiqc ./${DIR}_fastqc/

```

</details>

[MultiQC report](assets/raw_multiqc/multiqc_report.html)


## Adapter removal

<details>
<sumary>Trim sequence adapters</summary>

```


```

</details>