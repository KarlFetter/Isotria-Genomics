#!/bin/bash
#SBATCH --job-name=QC_Trim
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 4
#SBATCH --mem=50G
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mail-type=ALL
#SBATCH --mail-user=kcf@uconn.edu
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err

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