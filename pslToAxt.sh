#!/bin/bash

# global variables
maxGap=100 # parameter to chainToAxt

echo "# This program converts each psl file into AXT format through
# chain file, using the commands pslToChain and chainToAxt"

if [[ $# -lt 3 ]]; then
	echo "Usage: $0 <psl-file> <query.2bit> <target.2bit> [<out-dir>]"
	echo "query.2bit and target.2bit are the two files containing the"
	echo "sequences for the query and target in psl file"
	echo "Note: The psl filename must have the extension .psl"
	exit 1;
fi

pslFile=$1
query=$2
target=$3
if [[ -n $4 ]]; then
	outDir=$4
else
	outDir='.'
fi

chainFile=${pslFile/%psl/chain}
chainFile=$outDir/$chainFile
axtFile=${pslFile/%psl/axt}
axtFile=$outDir/$axtFile

#[[ $pslFile =~ dm3To([^\.]*).psl ]]
#sp=${BASH_REMATCH[1]}

bin=`dirname $0`
correctChainExe=$bin/correct_chain_fields.sh

echo Step 1: convert PSL to chain
tmpFile=$chainFile.tmp.$$
pslToChain $pslFile $tmpFile
# correct the errors in the fields qStart and qEnd
$correctChainExe $tmpFile | \
gzip -f -c >$chainFile.gz # and compress it
rm $tmpFile # remove temp file

echo Step 2: conver chain to axt
#axtFile=$axtDir/dm3To$sp.axt
#target=$gpath/${sp~}/bigZips/${sp~}.2bit
chainToAxt -maxGap=$maxGap $chainFile.gz $target $query $axtFile
gzip -f -S .gz $axtFile

echo Work done!
echo The results are stored in $chainFile.gz and $axtFile.gz

