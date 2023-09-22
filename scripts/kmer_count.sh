#!/bin/bash
#SBATCH --job-name=kmerCount
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 30 
#SBATCH --partition=himem
#SBATCH --qos=himem
#SBATCH --mail-type=END
#SBATCH --mem=375G
#SBATCH --mail-user=kcf@uconn.edu
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err


module load jellyfish/2.2.6

readDir=/core/projects/EBP/conservation/isotria/kmer_methods/02_quality_control/kraken
readpair=Fetter_Orchid_lysed_S449_L003_trim_unclassified

jellyfish count -t 30 -C -m 21 -s 100G -o 21mer_out $readDir/${readpair}_*.fastq
