#!/bin/bash

debug=0 # change to 1 if wants to keep temporary files

echo '#************ Info ******************'
echo "#This program is to process the chains produced by"
echo "#UCSC tools, and to produce:"
echo '#'1. net file
echo '#'2. axtNet file
echo '#'3. liftOver.chain file
echo '#'if the 3rd parameter is 1, maf files will also be \
generated.
echo '#************ End  ******************'

# stop if any error
set -e


if [[ $# -lt 3 ]]; then
	echo ''
	echo usage: $0 '<target-name> <query-name> <chain-dir> [1 or 0]'
	echo This script processes the chains stored in the \
	\$chain directory produced by lastz/axtChain, in \
	particular, by the script lastz_submit.sh. 
	echo ''
	
	exit 1;
fi

TNAME=$1
QNAME=$2
chain=$3 # the chain dir
more=$4

echo -e "*>> Processing chains $TNAME vs $QNAME <<*\n"

echo -e ">>>\nput all chains in $chain together and sort\n"
#find $chain -name "*.chain" | chainMergeSort -inputList=stdin \ #
# this version search the whole hierachy of folders
find $chain -maxdepth 1 -name "*.chain" | chainMergeSort -inputList=stdin \
 | gzip -c > ${TNAME}.${QNAME}.all.chain.gz

echo -e ">>>\nmaking net\n"
zcat ${TNAME}.${QNAME}.all.chain.gz | chainPreNet stdin \
$TNAME.chrom.sizes $QNAME.chrom.sizes stdout \
 | chainNet -minSpace=1 stdin $TNAME.chrom.sizes \
 $QNAME.chrom.sizes stdout $QNAME.tmp.net | netSyntenic \
 stdin ${TNAME}.${QNAME}.noClass.net

# add repeatMasking information, here dm3 and dp3 are UCSC database
# names, through mysql, netClass gets information from UCSC
# ** Skip this step as data is not readable from UCSC **#
#echo -e ">>>\nannotating net\n"
#netClass -noAr ${TNAME}.${QNAME}.noClass.net $TNAME $QNAME \
#stdout | gzip -c >${TNAME}.${QNAME}.net.gz
cat ${TNAME}.${QNAME}.noClass.net | gzip -c >${TNAME}.${QNAME}.net.gz

echo -e ">>>\nmaking liftOver file\n"
netChainSubset -verbose=0 ${TNAME}.${QNAME}.net.gz \
${TNAME}.${QNAME}.all.chain.gz stdout | chainStitchId stdin stdout \
 | gzip -c >${TNAME}.${QNAME}.over.chain.gz


echo -e ">>>\nmaking axtNet file for each target sequence in axtNet/\n"
mkdir -p net_by_chr
netSplit ${TNAME}.${QNAME}.net.gz net_by_chr

mkdir -p axtNet
for f in net_by_chr/*.net
do
	out=`basename $f`
	chr=${out%.net}
	netToAxt $f ${TNAME}.${QNAME}.all.chain.gz $TNAME.2bit \
	$QNAME.2bit stdout | axtSort stdin stdout \
	| gzip -c >axtNet/$chr.${TNAME}.${QNAME}.net.axt.gz
done

if [[ $debug -eq 0 ]]; then
	echo '# Removing temporary files'
	rm -rf net_by_chr ${QNAME}.tmp.net ${TNAME}.${QNAME}.noClass.net
fi

### **********************
if [[ ! $more ]]; then
	echo '*>>' Processing $chain is done '<<*'
	exit 0
fi

# generate more stuffs

echo -e ">>>\ngenerating Maf alignment\n"
zcat axtNet/*.net.axt.gz | axtToMaf stdin \
$TNAME.chrom.sizes $QNAME.chrom.sizes stdout \
 -tPrefix=$TNAME. -qPrefix=$QNAME. | gzip -c \
  >${TNAME}.${QNAME}.maf.gz # can split with mafSplit

echo '*>>' Processing $chain is done '<<*'
exit 0

