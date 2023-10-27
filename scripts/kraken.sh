#!/bin/bash
#SBATCH --job-name=kraken
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 16 
#SBATCH --partition=himem
#SBATCH --qos=himem
#SBATCH --mem=100G
#SBATCH --output=R-%x.%j.out
#SBATCH --error=R-%x.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=kcf@uconn.edu

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