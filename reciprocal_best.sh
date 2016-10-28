#!/bin/bash

set -e

echo This script is to get the reciprocal best regions starting \
from the liftOver file.

if [[ $# -lt 3 ]]; then
	echo Usage: $0 '<Target-Name> <Query-Name> <data-dir>'
	echo Example: $0 dmel_r5 dpse_r3 result/
	exit 1;
fi

T=$1
Q=$2
D=$3
t2Bit=$T.2bit
q2Bit=$Q.2bit
tSize=$T.chrom.sizes
qSize=$Q.chrom.sizes

function color_key ()
{
	norm="\e[0m"
	#red="\e[91;107m"
	red="\e[91m" # no need background
	echo -e "$red$1$norm $2"
}

#echo -e "\e[91;107mStep 1\e[0m: swap the target in the liftOver file"
color_key "Step 1:" "swap the target in the liftOver file"
chainStitchId $D/$T.$Q.over.chain.gz stdout | chainSwap \
stdin stdout | chainSort stdin $Q.$T.tBest.chain

color_key "Step 2:" "net on the new target sequence of chain file"
chainPreNet $Q.$T.tBest.chain $qSize \
$tSize stdout | chainNet -minSpace=1 -minScore=0 stdin \
$qSize $tSize stdout /dev/null | \
netSyntenic stdin stdout | gzip -c >$Q.$T.rBest.net.gz

#echo -e "\e[91;107mStep 3\e[0m: Extract new-target-referenced reciprocal \
#best chain"
color_key "Step 3:" "Extract new-target-referenced reciprocal best chain"
netChainSubset $Q.$T.rBest.net.gz \
$Q.$T.tBest.chain stdout | chainStitchId stdin stdout | \
gzip -c >$Q.$T.rBest.chain.gz

color_key "Step 4:" "Extract old-target-referenced reciprocal best chain"
# just swap
chainSwap $Q.$T.rBest.chain.gz stdout | chainSort stdin \
stdout | gzip -c >$T.$Q.rBest.chain.gz

color_key "Step 5:" "Get the old-target-referenced reciprocal best net"
chainPreNet $T.$Q.rBest.chain.gz $tSize \
$qSize stdout | chainNet -minSpace=1 -minScore=0 stdin \
$tSize $qSize stdout /dev/null | \
netSyntenic stdin stdout | gzip -c >$T.$Q.rBest.net.gz

color_key "Step 6:" "Clean up and generate md5sum file"
rm $Q.$T.tBest.chain
md5sum *.rBest.*.gz >md5sum.rbest.txt

color_key "Step 7:" "Calculate genome coverage by alignments (chain/net)"
netToBed -maxGap=1 $Q.$T.rBest.net.gz $Q.$T.rBest.net.bed
netToBed -maxGap=1 $T.$Q.rBest.net.gz $T.$Q.rBest.net.bed

chainToPsl $Q.$T.rBest.chain.gz $qSize $tSize \
$q2Bit $t2Bit $Q.$T.rBest.chain.psl

chainToPsl $T.$Q.rBest.chain.gz $tSize $qSize \
$t2Bit $q2Bit $T.$Q.rBest.chain.psl
#chainToPsl dmel_r5.dpse_r3.rBest.chain.gz dmel_r5.chrom.sizes \
#dpse_r3.chrom.sizes dmel_r5.2bit dpse_r3.2bit \
#dmel_r5.dpse_r3.rBest.chain.psl

tChCov=`awk '{print $19;}' $T.$Q.rBest.chain.psl | sed -e \
's/,/\n/g' | awk 'BEGIN {N = 0;} {N += $1;} END {printf "%d\n", N;}'`
qChCov=`awk '{print $19;}' $Q.$T.rBest.chain.psl | sed -e \
's/,/\n/g' | awk 'BEGIN {N = 0;} {N += $1;} END {printf "%d\n", N;}'`
tNetCov=`awk 'BEGIN {N = 0;} {N += ($3 - $2);} END {printf "%d\n",N;}' $T.$Q.rBest.net.bed`
qNetCov=`awk 'BEGIN {N = 0;} {N += ($3 - $2);} END {printf "%d\n",N;}' $Q.$T.rBest.net.bed`

printf "Coverage:\ntNet: %8d; qNet: %8d; tChain: %8d; qChain: %8d\n" \
$tNetCov $qNetCov $tChCov $qChCov >chain_net_coverage.txt
echo "All these 4 values should be the same" >>chain_net_coverage.txt

# verify the calculations
if [[ $tChCov -ne $qChCov ]]; then
	echo "Warning: chain coverages are not equal: $tChCov vs $qChCov"
fi

if [[ $tNetCov -ne $qNetCov ]]; then
	echo "Warning: net coverages are not equal: $tNetCov vs $qNetCov"
fi

if [[ $tNetCov -ne $tChCov ]]; then
	echo "Warning: net coverage doesn't equal chain coverage in \
	target: $tNetCov vs $tChCov"
fi

if [[ $qNetCov -ne $qChCov ]]; then
	echo "Warning: net coverage doesn't equal chain coverage in \
	query: $qNetCov vs $qChCov"
fi

# if want axt/maf files, use netSplit, chainSplit, netToAxt, axtToMaf

echo All Done!!

exit 0;


