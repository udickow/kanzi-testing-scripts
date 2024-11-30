#! /bin/bash
# Author: Ulrik Dickow <udickow@gmail.com>, 2024-11-03.
# Purpose: print lines with compressed size and algorithm for given input file (at most ~8 MiB recommended),
#   mostly trying lots of different transform-entropy kombis for kanzi in parallel after initial non-parallel
#   testing of a few other compressors and the level 1-9 kanzi presets.
#   This script is _not_ for speed testing.  Each compression is single-threaded.
# Changes:
#   ukd v03 2024-11-30: Add kanzi -l X with blocksize 64M too; add -x64 to all kanzi; add zpaq -m46; add xz 9e;
#                       add EXE transform to the parallel kanzi tests too
#   ukd v02 2024-11-03: Add zpaq with 64M buffer and change parallel kanzi blocksize to 64M since it can increase
#                       compression ratio by as much as 2.6% going from 8m to 16m even for only 3.6m input

if [ $# -ne 1 -o ! -r "$1" ]; then
    echo "Usage: $0 FILE"
    exit 1
fi
# export to be used by GNU parallel later
export ifile="$1"

# Other than kanzi first:

printf '%9d cat\n'   $(cat "$ifile"|wc -c)
printf '%9d gzip -9\n' $(gzip -9c "$ifile"|wc -c)
printf '%9d lz4 -12\n' $(lz4 -12c "$ifile"|wc -c)
printf '%9d zstd -19\n' $(zstd -19c "$ifile"|wc -c)
printf '%9d zstd --ultra -22\n' $(zstd --ultra -22c "$ifile"|wc -c)
printf '%9d bzip2\n' $(bzip2 -c "$ifile"|wc -c)
printf '%9d xz\n'    $(xz -c "$ifile"|wc -c)
printf '%9d xz -e\n' $(xz -ec "$ifile"|wc -c)
printf '%9d xz --lzma2=preset=6,lc=4,pb=0\n' $(xz -c --lzma2=preset=6,lc=4,pb=0 "$ifile"|wc -c)
printf '%9d xz --lzma2=preset=6e,lc=4,pb=0\n' $(xz -c --lzma2=preset=6e,lc=4,pb=0 "$ifile"|wc -c)
printf '%9d xz --lzma2=preset=9e,lc=4,pb=0\n' $(xz -c --lzma2=preset=9e,lc=4,pb=0 "$ifile"|wc -c)
printf '%9d bzip3\n' $(bzip3 -c "$ifile"|wc -c)

printf '%9d lrzip -p1 \n'  $(lrzip -p1 -qo- "$ifile"|wc -c)
printf '%9d lrzip -zp1 \n' $(lrzip -zp1 -qo- "$ifile"|wc -c)
printf '%9d zpaq a ... -m46 -t1\n' \
       $(t=`mktemp` && zpaq a $t "$ifile" -m46 -t1 >& /dev/null && wc -c < $t && rm $t)
printf '%9d zpaq a ... -m53 -t1\n' \
       $(t=`mktemp` && zpaq a $t "$ifile" -m53 -t1 >& /dev/null && wc -c < $t && rm $t)
printf '%9d zpaq a ... -m56 -t1\n' \
       $(t=`mktemp` && zpaq a $t "$ifile" -m56 -t1 >& /dev/null && wc -c < $t && rm $t)
printf '%9d arj\n' \
       $(t=`mktemp -u` && arj a $t "$ifile" > /dev/null && wc -c < $t && rm $t)
printf '%9d 7za a ... -m0=ppmd -mmt1\n' \
       $(t=`mktemp -u` && 7za a -m0=ppmd -mmt1 $t "$ifile" > /dev/null && wc -c < $t && rm $t)

# 7za ppmd order 2 to 32 (entire valid range)(and force buffer size 64 MiB)
for o in {2..32}; do
    printf "%9d 7za a ... -m0=ppmd:mem=26:o=$o -mmt1\n" \
	   $(t=`mktemp -u` && 7za a -m0=ppmd:mem=26:o=$o -mmt1 $t "$ifile" > /dev/null && wc -c < $t && rm $t)
done

# kanzi level 1 to 9 with the default blocksize for each level (higher levels default to larger sizes)
for level in {1..9}; do
    printf "%9d kanzi -x64 -l $level -j 1\n" $(kanzi -c -x64 -l $level -j 1 -i "$ifile" -o stdout|wc -c)
done

# kanzi level 1 to 9 with 64m blocksize for all levels
for level in {1..9}; do
    printf "%9d kanzi -x64 -b 64m -l $level -j 1\n" $(kanzi -c -x64 -b 64m -l $level -j 1 -i "$ifile" -o stdout|wc -c)
done

# kanzi with one transform (including NONE) and one entropy coding, testing 8 in parallel, forcing blocksize 64 MiB
#   (for 2+ transforms we will drop the last 2 in trans_list)
trans_list="NONE PACK BWT BWTS LZ LZX LZP ROLZ ROLZX RLT ZRLT MTFT RANK SRT TEXT DNA EXE MM UTF"
entropy_list="NONE HUFFMAN ANS0 ANS1 RANGE CM FPAQ TPAQ TPAQX"
for t1 in $trans_list; do
    for e in $entropy_list; do
	echo -x64 -b 64m -t $t1 -e $e
    done
done | parallel -j8 'printf "%9d kanzi {=uq=}\n" $(kanzi -c -j 1 {=uq=} -i $ifile -o stdout|wc -c)'

# kanzi with two non-null transforms and one entropy coding, testing 8 in parallel, forcing blocksize 64 MiB
trans_list="PACK BWT BWTS LZ LZX LZP ROLZ ROLZX RLT ZRLT MTFT RANK SRT TEXT DNA EXE"
for t1 in $trans_list; do
    for t2 in $trans_list; do
	# Two identical transforms in a row isn't useful, skip that
	if [ $t1 != $t2 ]; then
	    for e in $entropy_list; do
		echo -x64 -b 64m -t ${t1}+${t2} -e $e
	    done
	fi
    done
done | parallel -j8 'printf "%9d kanzi {=uq=}\n" $(kanzi -c -j 1 {=uq=} -i $ifile -o stdout|wc -c)'

# kanzi with 3 non-null transforms and one entropy coding, testing 8 in parallel, forcing blocksize 64 MiB
trans_list="PACK BWT BWTS LZ LZX LZP ROLZ ROLZX RLT ZRLT MTFT RANK SRT TEXT DNA EXE"
for t1 in $trans_list; do
    for t2 in $trans_list; do
	# Two identical transforms in a row isn't useful, skip that
	if [ $t1 != $t2 ]; then
	    for t3 in $trans_list; do
		# Two identical transforms in a row isn't useful, skip that
		if [ $t2 != $t3 ]; then
		    for e in $entropy_list; do
			echo -x64 -b 64m -t ${t1}+${t2}+${t3} -e $e
		    done
		fi
	    done
	fi
    done
done | parallel -j8 'printf "%9d kanzi {=uq=}\n" $(kanzi -c -j 1 {=uq=} -i $ifile -o stdout|wc -c)'
