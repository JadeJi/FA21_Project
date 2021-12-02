#!/bin/sh
#
####SBATCH --job-name=final_project
#SBATCH --time=72:00:00
#SBATCH --ntasks=5
#SBATCH --cpus-per-task=1
#SBATCH --partition=shared

export TMPDIR='/scratch/users/s-rji6@jhu.edu/tmp'
export LC_ALL=en_US.utf-8
export LANG=en_US.utf-8

#load qiime module
module load qiime2/2018.8

#This is the new folder that the analysis will be done in
OUTPUT="fianl_project_results"
mkdir ${OUTPUT}

#This sample contains information about which samples are associated with the ids
METADATA="/ibox/t-sprehei1/class_data/Chesapeake_Bay/sample_metadata_upper_lower_paired_subset.txt"

#This is the list of sequence files to import
MANIFEST="pipeline_test_manifest.csv2"

#Variables will allow you to analyze different parts of the data
VAR1="WaterColumnPosition"

#This is the read depth, how many data points should be included in each sample.
#Uneven read depths will skew your diversity analyses.
DEPTH=1000


# wget \
#  -O "sample-metadata.tsv" \
#  "https://data.qiime2.org/2018.8/tutorials/moving-pictures/sample_metadata.tsv"

# mkdir emp-single-end-sequences

#wget \
#  -O "emp-single-end-sequences/barcodes.fastq.gz" \
#  "https://data.qiime2.org/2018.8/tutorials/moving-pictures/emp-single-end-sequences/barcodes.fastq.gz"

#wget \
#  -O "emp-single-end-sequences/sequences.fastq.gz" \
#  "https://data.qiime2.org/2018.8/tutorials/moving-pictures/emp-single-end-sequences/sequences.fastq.gz"

#qiime tools import \
#  --type EMPSingleEndSequences \
#  --input-path emp-single-end-sequences \
#  --output-path emp-single-end-sequences.qza

#echo "Demuxing"
#date

#qiime demux emp-single \
#  --i-seqs emp-single-end-sequences.qza \
#  --m-barcodes-file sample-metadata.tsv \
#  --m-barcodes-column BarcodeSequence \
#  --o-per-sample-sequences demux.qza



qiime tools import\
   --type 'SampleData[PairedEndSequencesWithQuality]' \
   --input-path ${MANIFEST} \
   --output-path ${OUTPUT}/demux.qza \
   --input-format PairedEndFastqManifestPhred33

#Get the metadata file into the format that is called below
 cp ${METADATA} ${OUTPUT}/sample-metadata.tsv


# qiime demux summarize \
#  --i-data demux.qza \
#  --o-visualization demux.qzv



#qiime dada2 denoise-single \
#  --i-demultiplexed-seqs demux.qza \
#  --p-trim-left 0 \
#  --p-trunc-len 120 \
#  --o-representative-sequences rep-seqs-dada2.qza \
#  --o-table table-dada2.qza \
#  --o-denoising-stats stats-dada2.qza

qiime dada2 denoise-paired \
  --i-demultiplexed-seqs ${OUTPUT}/demux.qza \
  --p-trim-left-f 23 \
   --p-trim-left-r 23 \
   --p-trunc-len-f 200 \
   --p-trunc-len-r 200\
  --p-n-threads 0 --p-min-fold-parent-over-abundance 10\
  --o-representative-sequences ${OUTPUT}/rep-seqs-dada2.qza \
  --o-table ${OUTPUT}/table-dada2.qza \
  --o-denoising-stats ${OUTPUT}/stats-dada2.qza 


qiime metadata tabulate \
  --m-input-file ${OUTPUT}/stats-dada2.qza \
  --o-visualization ${OUTPUT}/stats-dada2.qzv

mv ${OUTPUT}/rep-seqs-dada2.qza ${OUTPUT}/rep-seqs.qza
mv ${OUTPUT}/table-dada2.qza ${OUTPUT}/table.qza

qiime feature-table summarize \
  --i-table ${OUTPUT}/table.qza \
  --o-visualization ${OUTPUT}/table.qzv \
  --m-sample-metadata-file ${OUTPUT}/sample-metadata.tsv
qiime feature-table tabulate-seqs \
  --i-data ${OUTPUT}/rep-seqs.qza \
  --o-visualization ${OUTPUT}/rep-seqs.qzv

qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences ${OUTPUT}/rep-seqs.qza \
  --o-alignment ${OUTPUT}/aligned-rep-seqs.qza \
  --o-masked-alignment ${OUTPUT}/masked-aligned-rep-seqs.qza \
  --o-tree ${OUTPUT}/unrooted-tree.qza \
  --o-rooted-tree ${OUTPUT}/rooted-tree.qza

qiime diversity core-metrics-phylogenetic \
  --i-phylogeny ${OUTPUT}/rooted-tree.qza \
  --i-table ${OUTPUT}/table.qza \
  --p-sampling-depth ${DEPTH} \
  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
  --output-dir ${OUTPUT}/core-metrics-results

qiime diversity alpha-group-significance \
  --i-alpha-diversity ${OUTPUT}/core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
  --o-visualization ${OUTPUT}/core-metrics-results/faith-pd-group-significance.qzv

qiime diversity alpha-group-significance \
  --i-alpha-diversity ${OUTPUT}/core-metrics-results/evenness_vector.qza \
  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
  --o-visualization ${OUTPUT}/core-metrics-results/evenness-group-significance.qzv

qiime diversity beta-group-significance \
  --i-distance-matrix ${OUTPUT}/core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
  --m-metadata-column ${VAR1} \
  --o-visualization ${OUTPUT}/core-metrics-results/unweighted-unifrac-var1-significance.qzv \
  --p-pairwise

# qiime diversity beta-group-significance \
#  --i-distance-matrix ${OUTPUT}/core-metrics-results/unweighted_unifrac_distance_matrix.qza \
#  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
#  --m-metadata-column Subject \
#  --o-visualization ${OUTPUT}/core-metrics-results/unweighted-unifrac-subject-group-significance.qzv \
#  --p-pairwise

# qiime emperor plot \
#  --i-pcoa core-metrics-results/unweighted_unifrac_pcoa_results.qza \
#  --m-metadata-file sample-metadata.tsv \
#  --p-custom-axes DaysSinceExperimentStart \
#  --o-visualization core-metrics-results/unweighted-unifrac-emperor-DaysSinceExperimentStart.qzv

# qiime emperor plot \
#  --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza \
#  --m-metadata-file sample-metadata.tsv \
#  --p-custom-axes DaysSinceExperimentStart \
#  --o-visualization core-metrics-results/bray-curtis-emperor-DaysSinceExperimentStart.qzv

qiime diversity alpha-rarefaction \
  --i-table ${OUTPUT}/table.qza \
  --i-phylogeny ${OUTPUT}/rooted-tree.qza \
  --p-max-depth ${DEPTH} \
  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
  --o-visualization ${OUTPUT}/alpha-rarefaction.qzv

wget \
  -O "${OUTPUT}/gg-13-8-99-515-806-nb-classifier.qza" \
  "https://data.qiime2.org/2018.8/common/gg-13-8-99-515-806-nb-classifier.qza"

qiime feature-classifier classify-sklearn \
  --i-classifier ${OUTPUT}/gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads ${OUTPUT}/rep-seqs.qza \
  --o-classification ${OUTPUT}/taxonomy.qza

qiime metadata tabulate \
  --m-input-file ${OUTPUT}/taxonomy.qza \
  --o-visualization ${OUTPUT}/taxonomy.qzv

qiime taxa barplot \
  --i-table ${OUTPUT}/table.qza \
  --i-taxonomy ${OUTPUT}/taxonomy.qza \
  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
  --o-visualization ${OUTPUT}/taxa-bar-plots.qzv

# qiime feature-table filter-samples \
#  --i-table table.qza \
#  --m-metadata-file sample-metadata.tsv \
#  --p-where "BodySite='gut'" \
#  --o-filtered-table gut-table.qza

qiime composition add-pseudocount \
  --i-table ${OUTPUT}/table.qza \
  --o-composition-table ${OUTPUT}/comp-table.qza

qiime composition ancom \
  --i-table ${OUTPUT}/comp-table.qza \
  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
  --m-metadata-column ${VAR1} \
  --o-visualization ${OUTPUT}/ancom.qzv

qiime taxa collapse \
  --i-table ${OUTPUT}/table.qza \
  --i-taxonomy ${OUTPUT}/taxonomy.qza \
  --p-level 6 \
  --o-collapsed-table ${OUTPUT}/table-l6.qza

qiime composition add-pseudocount \
  --i-table ${OUTPUT}/table-l6.qza \
  --o-composition-table ${OUTPUT}/comp-table-l6.qza

qiime composition ancom \
  --i-table ${OUTPUT}/comp-table-l6.qza \
  --m-metadata-file ${OUTPUT}/sample-metadata.tsv \
  --m-metadata-column ${VAR1} \
  --o-visualization ${OUTPUT}/l6-ancom-Subject.qzv


