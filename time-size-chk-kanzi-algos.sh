#! /bin/bash
# -*- indent-tabs-mode: nil; -*-
# Copyright 2025-2026 Ulrik Dickow <u.dickow@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Purpose: For a single given input file, test kanzi compression and decompression with each possible transform,
#   entropy codec and preset level in turn, plus a few custom combinations.  Verify that the decompression
#   output has the same sha256sum (or other external checksum) as the original file.  Produce a single line of
#   output for each test with this information:
#
#     Checksum_status(OK/FAIL) Compressed_size(bytes) Compression_time(ms) Decompression_time(ms) | Kanzi_args...
#
#   The timings are the net values measured by kanzi itself.
#   If used with a not-too-large input file, this script is also useful for the profile data gathering phase
#   of a PGO-build of kanzi (Profile Guided Optimization).
#
# Changes: See https://github.com/udickow/kanzi-testing-scripts

if [ $# -ne 1 -o ! -r "$1" ]; then
    echo "Usage: $0 FILE" >&2
    exit 1
fi
infile="$1"

# Kanzi binary to use for testing compression and decompression
KANZI="${KANZI:-kanzi}"

# Hash program to use for checksumming
HASHPROG="${HASHPROG:-sha256sum}"

# Number of threads (-j) for each kanzi run except the one with 256m blocksize.
NJOBS="${NJOBS:-$(($(nproc) / 2))}"

csumstr1=$("$HASHPROG" < "$infile")
if [ $? -ne 0 -o "X$csumstr1" = "X" ]; then
    echo "$0: Hash program '$HASHPROG' failed reading file '$infile', exiting" >&2
    exit 1
fi

# Temporary compressed file and temporary decompressed version of the compressed file (to time & checksum)
ctfile=$(mktemp --suffix .knz)
dtfile=$(mktemp)

do_test () {
    status="FAIL"
    csize="-"
    ctime="-"
    dtime="-"

    # As of kanzi 2.4.0 verbosity level 1 is default but specify explicitly anyway in case it changes later on
    clines=$("$KANZI" -c -x64 -v 1 -i "$infile" -f -o "$ctfile" "$@")
    if [ $? -eq 0 ]; then
        # Parse output expected to contain a line like one of these, converting seconds to milliseconds:
        #   Compressed enwik7:  10000000 => 2106385 (21.06%) in 3061 ms
        #   Compressed some..:  652000000 => 54154215 (8.31%) in 104.6 s
        eval $(perl -lne '/=>\s*(\d+) .* ([\d.]+) (m?s)/ and print "csize=$1; ctime=".($3 eq "s" ? 1000*$2 : $2)' <<<"$clines")
        dlines=$("$KANZI" -d -v 1 -i "$ctfile" -f -o "$dtfile" "$@")
        if [ $? -eq 0 ]; then
            # Parse output expected to contain a line like one of these, converting seconds to milliseconds:
            #   Decompressed tmp.Jkk5fQDZ2g.knz: 2106385 => 10000000 bytes in 3263 ms
            #   Decompressed tmp............: 11038665 => 1416769759 bytes in 159.2 s
            eval $(perl -lne '/ in ([\d.]+) (m?s)/ and print "dtime=".($2 eq "s" ? 1000*$1 : $1)' <<<"$dlines")
            csumstr2=$("$HASHPROG" < "$dtfile")
            [ "X$csumstr1" = "X$csumstr2" ] && status="OK"
        fi
    fi
    single_string_args="$@"
    printf "%-4s %10d %7d %7d  |  -x64 %s\n" "$status" "$csize" "$ctime" "$dtime" "$single_string_args"
}

# All valid transforms and entropy codecs, respectively, as of kanzi 2.4.0-2.6.0 -- plus new added after 2.6.0
trans_list="NONE PACK BWT BWTS LZF LZ LZX LZP LZPX ROLZ ROLZX RLT ZRLT MTFT RANK SRT TEXT EXE MM UTF DNA"
entropy_list="HUFFMAN HUFFMAN1 ANS0 ANS1 RANGE FPAQ CM TPAQ TPAQX"

# Using default blocksize (4m as of 2.4.0) for the transform tests
for t in $trans_list; do
    do_test -j "$NJOBS" -t $t -e NONE
done

# Let's use blocksize 64m for all of the entropy tests here
for e in $entropy_list; do
    do_test -b 64m -j "$NJOBS" -t NONE -e $e
done

# kanzi level 1 to 9 with the default blocksize for each level (higher levels default to larger sizes).
for level in {1..9}; do
    do_test -j "$NJOBS" -l $level
done

# Finally two custom combinations of transforms and entropy codecs optimal for some file types (see wiki)
do_test -b 64m -j "$NJOBS" -t TEXT+BWTS+SRT+ZRLT -e TPAQ
do_test -b 256m -j 1 -t EXE+TEXT+RLT+UTF+PACK -e TPAQX

rm "$ctfile" "$dtfile"
