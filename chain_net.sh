############################################################
# Pipeline to generate chain/net files between two genomes
# based on the information from the following two sites:
# http://genomewiki.ucsc.edu/index.php/Whole_genome_alignment_howto and
# http://genomewiki.ucsc.edu/images/9/93/RunLastzChain_sh.txt
###########################################################
# specifically, I will make the alignments for Dmel_r5 and Dsim_r2
# >>> Note: all the script has to been run in the same working folder <<<

# step 1: softmasking the sequences with repeatmasker and tandem repeat finder
# For masking the tandem repeats, ucsc has a tool trfBig.

# step 1a: eliminate nonchromosomal sequences, optional
# this is to reduce the pairwise lastz/blastz search between two genomes,
# because when running the search on a computer cluster, this may lead to 
# too many jobs/tasks. One solution is join short sequences together by adding
# chunks of Ns between them, just as UCSC does. Here, I removed nonchromosomal
# sequences from the two well assembled genomes and keep the sequence lists in
# the following files dmel_r5.kept_seqs and dsim_r2.kept_seqs, then I extracted
# these kept sequences from parent .2bit file
cut -f 1 dmel_r5.kept_seqs >tmp1
twoBitToFa ../dmel_r5.2bit tmp2 -seqList=tmp1
faToTwoBit tmp2 dmel.2bit
cut -f 1 dsim_r2.kept_seqs >tmp1
twoBitToFa ../dsim_r2.2bit tmp2 -seqList=tmp1
faToTwoBit tmp2 dsim.2bit

# step 2: prepare sequences for running lastz or blastz
## including split large sequences into smaller chunks,
## here I use 10M chunks with 10K overlap. Check UCSC's
## readme file for their choice, e.g., ftp://hgdownload.cse.ucsc.edu/goldenPath/dm3/vsDroSim1/README.txt

# step 3: run chaining on the result of lastz
## this includes convert the resulted .lav files into psl, convert coordinates to global ones,
## and then chaining them with axtChain

## the above two steps have been combined into two scripts:
## lastz_submit.sh and run_lastz.sbc, the former calls the latter
## to run on a computer cluster with slurm job management.
lastz_submit.sh dmel dsim # run it on 120 CPUs, cost 2 minutes

# step 4: chainning the psl files for each target sequence
## the above running lastz_submit.sh has made chain for each psl
## file, but for making longer chains, it may be better to chain
## all the psl files of a target sequence togther (This has not been
## checked yet. Previously I found chaining psl individually or for a target
## together does not make much difference).
## this is done by running the slurm script on a cluster
sbatch chain_by_target.sbc # 1 cpu , 20G mem, used 5 minutes

# step 5: making the ..net file from the chains
## this is to find the best aligned query sequence for each target sequence region

# step 6: making the .axt files from the net file
## just converting format for later use

# step 7: making the .over.chain file from the net file
## this uses the software netChainSubset

### the above 3 steps are combined into one bash script ./process_chains.sh
### I run this script on a cumputer cluster by calling sbatch file
sbatch process_chain.sbc # 1 cpu with 20G mem, finished within 2 minutes

# step 8: choose the best reciprocal regions from .over.chain file
## this result in reciprocal best net file and best chain file
## all these has been implemented in a script reciprocal_best.sh
## so I run this script directly
module load scripts_bash
reciprocal_best.sh dmel dsim ./

# copy all the result into a folder
mv axtNet *.gz *.bed *.psl md5sum.rbest.txt chain_net_coverage.txt result/
mv axtNet *.gz *.bed *.psl md5sum.rbest.txt chain_net_coverage.txt result_noAnti/
mv axtNet *.gz *.bed *.psl md5sum.rbest.txt chain_net_coverage.txt result_single_psl/

## in terms of coverage of reciprocal regions: result_noAnti is the longest, and result_single_psl is the worst, but the difference is really tiny
## 108097858 vs 108078162 vs 108076780

