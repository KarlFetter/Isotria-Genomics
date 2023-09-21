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

hostname
date

module load Trimmomatic/0.39

readDir=/core/projects/EBP/conservation/isotria/kmer_methods/01_raw_reads/GenomeKmer_Orchid_Sept2023
readpair=Fetter_Orchid_lysed_S449_L003

SAM=K21
java -jar $Trimmomatic PE -threads 4 \
        $readDir/${readpair}_R1_001.fastq.gz \
        $readDir/${readpair}_R2_001.fastq.gz \
        trim_${readpair}_R1_001.fastq.gz singles_trim_${readpair}_R1.fastq.gz \
        trim_${readpair}_R2_001.fastq.gz singles_trim_${readpair}_R2.fastq.gz \
        ILLUMINACLIP:/isg/shared/apps/Trimmomatic/0.36/adapters/TruSeq3-PE-2.fa:2:30:10 \
        SLIDINGWINDOW:4:25 \
        MINLEN:45
date

```

</details>

<details>

<summary>The reporting and trimming is better done with fastp. Use these files gong forward.</summary>

```
echo `hostname`
date

#################################################################
# Trimming/QC of reads using fastp
#################################################################

module load fastp/0.23.2
 
# Set up directories
INDIR=/core/projects/EBP/conservation/isotria/kmer_methods/01_raw_reads/GenomeKmer_Orchid_Sept2023
readpair=Fetter_Orchid_lysed_S449_L003

REPORTDIR=/core/projects/EBP/conservation/isotria/kmer_methods/02_quality_control/fastp_reports
mkdir -p $REPORTDIR

TRIMDIR=/core/projects/EBP/conservation/isotria/kmer_methods/02_quality_control/trimmed_sequences
mkdir -p $TRIMDIR

# run fastp to trim and generate reports on reads
fastp \
    --in1 $INDIR/${readpair}_R1_001.fastq.gz \
    --in2 $INDIR/${readpair}_R2_001.fastq.gz \
    --out1 $TRIMDIR/${readpair}_trim_R1.fastq.gz \
    --out2 $TRIMDIR/${readpair}_trim_R2.fastq.gz \
    --json $REPORTDIR/${readpair}_fastp.json \
    --html $REPORTDIR/${readpair}_fastp.html

module purge

########################################################
## Quality Control with fastqc 
#########################################################

module load fastqc/0.11.7

FASTQC=/core/projects/EBP/conservation/isotria/kmer_methods/02_quality_control/fastqc_reports
mkdir -p $FASTQC

fastqc --outdir $FASTQC $TRIMDIR/${readpair}_trim_{R1..R2}.fastq.gz

```

</details>



<details>
<summary>Remove contaminants with kraken.</summary>

```
hostname
date

module load kraken/2.1.2
module load jellyfish/2.3.0

OUTDIR=/core/projects/EBP/conservation/isotria/kmer_methods/02_quality_control/kraken
mkdir -p $OUTDIR

readDir=/core/projects/EBP/conservation/isotria/kmer_methods/02_quality_control/trimmed_sequences
readpair=Fetter_Orchid_lysed_S449_L003_trim

kraken2 -db /isg/shared/databases/kraken2/Standard \
    --paired $readDir/${readpair}_R1.fastq.gz $readDir/${readpair}_R2.fastq.gz \
	--use-names \
	--threads 16 \
	--output $OUTDIR/${readpair}_kraken_general.out \
	--unclassified-out $OUTDIR/${readpair}_unclassified#.fastq \
	--classified-out $OUTDIR/${readpair}_classified#.fastq \
	--report $OUTDIR/${readpair}_kraken_report.txt \
	--use-mpa-style 



date
```

</details>