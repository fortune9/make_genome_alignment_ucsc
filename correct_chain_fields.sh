#!/bin/bash

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <chain-file, normal or gzipped>"
	echo "This program corrects the errors in the fields of qStart and"
	echo "qEnd of the input chain file when query is aligned in minus"
	echo "strand, the errors are due to the bug of pslToChain"
	exit 1;
fi

in=$1

if [[ $in =~ \.gz$ ]]; then
	# echo a compressed fil
	zcat $in | \
	gawk 'BEGIN{FS="[ ]+"}{if($1=="chain" && $10 == "-" ) {tmp=$9-$11;$11=$9-$12;$12=tmp;}; print $0}'
else
	# echo a normal file
	gawk 'BEGIN{FS="[ ]+"}{if($1=="chain" && $10 == "-" ) {tmp=$9-$11;$11=$9-$12;$12=tmp;}; print $0}' $in
fi

exit 0;


