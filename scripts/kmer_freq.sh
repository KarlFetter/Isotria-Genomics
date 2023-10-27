#!/bin/bash
#SBATCH --job-name=kmerFreq
#SBATCH -n 1
#SBATCH -c 1 
#SBATCH -N 1
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=4G
#SBATCH --output=R-%x.%j.out
#SBATCH --error=R-%x.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=kcf@uconn.edu

module load jellyfish/2.2.6

jellyfish histo -o 21mer_out.histo 21mer_out
