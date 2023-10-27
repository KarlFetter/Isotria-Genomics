# Kmer Based Genomic Methods

The raw reads and other large read files are moved to `/archive/labs/wegrzyn/genomes/orchids/` to save space on `/core/projects`. Sequences for a single pair of reads are available here, but they are symlinked to their paths in `/core/projects/EBP/conservation/isotria`. 

```
(base) bash-4.2$ ls -lht /archive/labs/wegrzyn/genomes/orchids/raw_reads/
total 358G
-rwxrwxrwx 1 kfetter wegrzynlab 184G Sep 11 10:41 Fetter_Orchid_lysed_S449_L003_R2_001.fastq.gz
-rwxrwxrwx 1 kfetter wegrzynlab 175G Sep 11 10:41 Fetter_Orchid_lysed_S449_L003_R1_001.fastq.gz
```

## Quality Control & Adapter Removal

<details>

<summary>Use fastp to evluate sequence quality and to trim adapter sequences.</summary>

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

[fastp QC report.](assets/Fetter_Orchid_lysed_S449_L003_fastp.html)

You can also use `fastqc` and `multiqc` to make the QC reports.

<details>
<summary>To use fastqc/multiqc, click here.</summary>

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

[MultiQC report](assets/multiqc_report.html)

## Kraken: Contaminant removal

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

<details>
<summary>Get a list of contaminated reads for removal.</summary>

```
cd 
awk '{ if ($2 ~ /contaminant_taxid/) print $1 }' Fetter_Orchid_lysed_S449_L003_trim_kraken_general.out > contaminant_ids.txt

```

</details>

Use the unclassified reads, which should be cleaned of contaminants.

## Jellyfish/Smudeplot: Kmer models to ploidy estimate

<details>
<summary>Run the kmer counting script (1kmer_count.sh). Be mindful of the resources required here, they are large.</summary>

```
#!/bin/bash
#SBATCH --job-name=kmerCount
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 30 
#SBATCH --partition=himem2
#SBATCH --qos=himem
#SBATCH --mail-type=END
#SBATCH --mem=475G
#SBATCH --mail-user=kcf@uconn.edu
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err

module load jellyfish/2.2.6

readDir=/core/projects/EBP/conservation/isotria/kmer_methods/02_quality_control/kraken
readpair=Fetter_Orchid_lysed_S449_L003_trim_unclassified

jellyfish count -C -m 21 -s 1000000000 -t 10 $readDir/${readpair}_*.fastq -o 21mer_out_reads.jf
```

</details>

<details>
<summary>Make the histogram of the kmers (.histo) with 2kmer_freq.sh.</summary>

```
module load jellyfish/2.2.6

jellyfish histo -t 10 21mer_out_reads.jf > 21mer_reads.histo
```

</details>

<details>
<summary>Create the upper and lower thresholds for the histogram (3kmer_threshold.sh).</summary>

```
module load singularity/3.7.1
smudgeplot=/isg/shared/databases/nfx_singularity_cache/smudgeplot.sif

singularity exec $smudgeplot smudgeplot.py cutoff 21mer_reads.histo L > cutoff_L.out
singularity exec $smudgeplot smudgeplot.py cutoff 21mer_reads.histo U > cutoff_U.out

# these need to be sane values like 30 800 or so
```

</details>

<details>
<summary>Run the smudgeplot.py on the 21mer_out_reads.jf. This step outputs the sequences.tsv and coverages.tsv of the 21mers. We are using a lower threshold of 88 here. (4kmer_extract_L88.sh)</summary>

```
#!/bin/bash
#SBATCH --job-name=kmerExtractL88
#SBATCH -n 1
#SBATCH -c 10
#SBATCH -N 1
#SBATCH --partition=general
#SBATCH --qos=general
#SBATCH --mem=150G
#SBATCH --output=R-%x.%j.out
#SBATCH --error=R-%x.%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=kcf@uconn.edu

module load singularity/3.7.1
module load jellyfish/2.2.6

smudgeplot=/isg/shared/databases/nfx_singularity_cache/smudgeplot.sif
L=88
U=1100

jellyfish dump -c -L $L -U $U 21mer_out_reads.jf | singularity exec $smudgeplot smudgeplot.py hetkmers -o kmer_pairs_L88

```

</details>


<details>
<summary>Make the smudgeplot to estimate ploidy level. (kmer_plot.sh)</summary>

```
module load singularity/3.7.1

smudgeplot=/isg/shared/databases/nfx_singularity_cache/smudgeplot.sif

singularity exec $smudgeplot smudgeplot.py plot kmer_pairs_L88_coverages.tsv -o isotria_smudgeplot_L88
```

</details>

<p>
  <figure>
    <a href="/core/projects/EBP/conservation/isotria/Isotria_Genomics/scripts/assets/isotria_smudgeplot_L88_smudgeplot.png">
      ![Isotria Smudgeplot](/core/projects/EBP/conservation/isotria/Isotria_Genomics/scripts/assets/isotria_smudgeplot_L88_smudgeplot.png)
    </a>
    <figcaption>Isotria smudgeplot indicating a diploid genome.</figcaption>
  </figure>
</p>

## GenomeScope: Model k-mer spectrum

## Genome Coverage estimate

```R
read_count = 2498500000
> read_length = 150
> genome1 = 2000000000
> genome1
[1] 2e+09
> genome2 = 50e9
> genome2
[1] 5e+10
> coverage1 = (read_count * read_length) / genome1
> coverage2 = (read_count * read_length) / genome2
> coverage1
[1] 187.3875
> coverage2
[1] 7.4955
```


