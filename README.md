# Kanzi testing scripts


This repository currently contains these bash scripts for testing and verifying [kanzi](https://github.com/flanglet/kanzi-cpp):

* [checksum-kanzi-d-filelist.sh](#checksum-kanzi-d-filelistsh)
* [recompress-old-kanzi-files.sh](#recompress-old-kanzi-filessh)
* [time-size-chk-kanzi-algos.sh](#time-size-chk-kanzi-algossh)
* [size-kanzi-algos-etc.sh](#size-kanzi-algos-etcsh)
* [pareto-convex.pl](#pareto-convexpl)
* [kanzi_benchmark.sh](#kanzi_benchmarksh)

## checksum-kanzi-d-filelist.sh

A quite short and simple script for generating a list of sha256sums of decompressions of kanzi-compressed files.
Includes almost no error checking, so completely failed kanzi decompressions will return the checksum of a zero-length file
like in this example where `kanzi` is a new version (July 2025) unable to decompress some earlier test files
(compressed with a December 2024 kanzi.old, bitstream version 6 format being in development and
[changing incompatibly](https://github.com/flanglet/kanzi-cpp/commit/140790b26a6acbd413b145d248f9967ff4cc00ad)
in that period):
```
$ ls -1 test.txt.knz-*tNONE* | ../checksum-kanzi-d-filelist.sh /dev/stdin; sha256sum /dev/null
91a0b88ca03915f704ce7155b119a1b5b24621419f23e9ed5e4320be026e01c3 test.txt.knz-new-tNONE_eTPAQ-no-size
91a0b88ca03915f704ce7155b119a1b5b24621419f23e9ed5e4320be026e01c3 test.txt.knz-new-tNONE_eTPAQ-with-size
Invalid bitstream, header checksum mismatch. Error code: 19
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 test.txt.knz-old-tNONE_eTPAQ-no-size
Invalid bitstream, header checksum mismatch. Error code: 19
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 test.txt.knz-old-tNONE_eTPAQ-with-size
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  /dev/null

$ ls -1 test.txt.knz-*tNONE*|KANZI=kanzi.old ../checksum-kanzi-d-filelist.sh /dev/stdin
Invalid bitstream, header checksum mismatch. Error code: 19
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 test.txt.knz-new-tNONE_eTPAQ-no-size
Invalid bitstream, header checksum mismatch. Error code: 19
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 test.txt.knz-new-tNONE_eTPAQ-with-size
91a0b88ca03915f704ce7155b119a1b5b24621419f23e9ed5e4320be026e01c3 test.txt.knz-old-tNONE_eTPAQ-no-size
91a0b88ca03915f704ce7155b119a1b5b24621419f23e9ed5e4320be026e01c3 test.txt.knz-old-tNONE_eTPAQ-with-size
```
Originally created for verifying a previously saved list of filenames and comparing a new list of checksums with an older one.
That's why it doesn't read the names of the compressed files as individual arguments.

## recompress-old-kanzi-files.sh

Recompresses kanzi-compressed files with the same blocksize, transforms and entropy codec as
they were previously compressed with, but possibly using another kanzi version for the initial
decompression than for the recompression.  The script also does this:

* verifies, possibly with a third kanzi version, that the recompressed file can be correctly decompressed
* adds 64-bit checksum at end of each block (option -x64 to kanzi) no matter if in original or not
* adds decompressed file size in file header (since compression done of real file, not from pipe)

See comments in script for more detail.  Example run:
```
$ ll
totalt 12
lrwxrwxrwx. 1 ukd ukd 35 17 jul 15:54 symlink-to-ignore.knz -> test.txt.knz-old-tLZX_eNONE-no-size
-rw-r-----. 1 ukd ukd 53 15 jul 11:09 test.txt.knz-new-tNONE_eTPAQ-no-size
-rwxr-xr-x. 1 ukd ukd 52 15 jul 11:30 test.txt.knz-old-tLZX_eNONE-no-size

### Will fail on new file but work for old:

$ OLDKANZI=kanzi.old ../recompress-old-kanzi-files.sh *.knz*
../recompress-old-kanzi-files.sh: 'symlink-to-ignore.knz' skipped because not a regular file or not readable
Invalid bitstream, header checksum mismatch. Error code: 19
../recompress-old-kanzi-files.sh: Error decompressing 'test.txt.knz-new-tNONE_eTPAQ-no-size', skipping it (consider changing OLDKANZI)
test.txt.knz-old-tLZX_eNONE-no-size : OK

$ ll
totalt 12
lrwxrwxrwx. 1 ukd ukd 35 17 jul 15:54 symlink-to-ignore.knz -> test.txt.knz-old-tLZX_eNONE-no-size
-rw-r-----. 1 ukd ukd 53 15 jul 11:09 test.txt.knz-new-tNONE_eTPAQ-no-size
-rwxr-xr-x. 1 ukd ukd 62 15 jul 11:30 test.txt.knz-old-tLZX_eNONE-no-size

### Test recompressing with new kanzi (will add size in header to new file, now no errors)

$ ../recompress-old-kanzi-files.sh *.knz*
../recompress-old-kanzi-files.sh: 'symlink-to-ignore.knz' skipped because not a regular file or not readable
test.txt.knz-new-tNONE_eTPAQ-no-size : OK
test.txt.knz-old-tLZX_eNONE-no-size : OK

$ ll
totalt 12
lrwxrwxrwx. 1 ukd ukd 35 17 jul 15:54 symlink-to-ignore.knz -> test.txt.knz-old-tLZX_eNONE-no-size
-rw-r-----. 1 ukd ukd 63 15 jul 11:09 test.txt.knz-new-tNONE_eTPAQ-no-size
-rwxr-xr-x. 1 ukd ukd 62 15 jul 11:30 test.txt.knz-old-tLZX_eNONE-no-size

### mtimes, permissions, blocksizes and transforms/codecs preserved; checksum and size in all headers

$ for f in test*;do echo "=== $f ==="; kanzi -d -v 3 -o none -i $f|grep -E 'Block|stage|Original';done
=== test.txt.knz-new-tNONE_eTPAQ-no-size ===
Block checksum: 64 bits
Block size: 4194304 bytes
Using TPAQ entropy codec (stage 1)
Using no transform (stage 2)
Original size: 27 bytes
=== test.txt.knz-old-tLZX_eNONE-no-size ===
Block checksum: 64 bits
Block size: 4194304 bytes
Using no entropy codec (stage 1)
Using LZX transform (stage 2)
Original size: 27 bytes
```

## time-size-chk-kanzi-algos.sh

For a single given input file, test kanzi compression and decompression with each possible transform,
entropy codec and preset level in turn, plus a few custom combinations.  Verify that the decompression
output has the same sha256sum (or other external checksum) as the original file.  Produce a single line of
output for each test with this information:

    Checksum_status(OK/FAIL) Compressed_size(bytes) Compression_time(ms) Decompression_time(ms) | Kanzi_args...

The timings are the net values measured by kanzi itself.

If used with a not-too-large input file, this script is also useful for the profile data gathering phase
of a PGO-build of kanzi with
[gcc](https://gcc.gnu.org/onlinedocs/gcc-15.2.0/gcc/Instrumentation-Options.html#index-fprofile-generate) or
[clang](https://clang.llvm.org/docs/UsersManual.html#profile-guided-optimization).

Sample run on the
[private 24.1 MiB highly redundant Fedora 30 Linux /var/log/boot.log test file](https://github.com/udickow/kanzi-testing-scripts/wiki/Test-file-descriptions#boot30):
```
$ llw kanzi
lrwxrwxrwx. 1 root root 84 29 dec 11:40 /usr/local/bin/kanzi -> [...]/kanzi-2.4.0.r107-ge4a0920b-gcc1431-skylake-nopic-lto-pgo

$ date;\time time-size-chk-kanzi-algos.sh boot-HOSTNAME-fc30big.log;date
lør  3 jan 10:26:05 CET 2026
OK     25260346      25      31  |  -x64 -j 8 -t NONE -e NONE
OK     13808350      31      20  |  -x64 -j 8 -t PACK -e NONE
OK     25260521     295     120  |  -x64 -j 8 -t BWT -e NONE
OK     25260346     444     519  |  -x64 -j 8 -t BWTS -e NONE
OK      2773009      19      15  |  -x64 -j 8 -t LZ -e NONE
OK      2668240      21      15  |  -x64 -j 8 -t LZX -e NONE
OK     14013493      23      22  |  -x64 -j 8 -t LZP -e NONE
OK       450282      23      24  |  -x64 -j 8 -t ROLZ -e NONE
OK       458797      29      28  |  -x64 -j 8 -t ROLZX -e NONE
OK     24578548      26      29  |  -x64 -j 8 -t RLT -e NONE
OK     25260346      25      27  |  -x64 -j 8 -t ZRLT -e NONE
OK     25260346     117      68  |  -x64 -j 8 -t MTFT -e NONE
OK     25260346      91      69  |  -x64 -j 8 -t RANK -e NONE
OK     25262900     113      54  |  -x64 -j 8 -t SRT -e NONE
OK     18330247      30      26  |  -x64 -j 8 -t TEXT -e NONE
OK     25260346      26      27  |  -x64 -j 8 -t EXE -e NONE
OK     25260346      26      28  |  -x64 -j 8 -t MM -e NONE
OK     25260346      25      27  |  -x64 -j 8 -t UTF -e NONE
OK     25260346      23      27  |  -x64 -j 8 -t DNA -e NONE
OK     16016475      65     118  |  -x64 -b 64m -j 8 -t NONE -e HUFFMAN
OK     15980907      99      90  |  -x64 -b 64m -j 8 -t NONE -e ANS0
OK      7434924     113     110  |  -x64 -b 64m -j 8 -t NONE -e ANS1
OK     15880823     115     294  |  -x64 -b 64m -j 8 -t NONE -e RANGE
OK      9665921    1265    1718  |  -x64 -b 64m -j 8 -t NONE -e CM
OK     14138154     420     529  |  -x64 -b 64m -j 8 -t NONE -e FPAQ
OK       456996    4094    4088  |  -x64 -b 64m -j 8 -t NONE -e TPAQ
OK       410744    5234    5169  |  -x64 -b 64m -j 8 -t NONE -e TPAQX
OK      2668240      21      16  |  -x64 -j 8 -l 1
OK      1912361      22      18  |  -x64 -j 8 -l 2
OK      1452114      42      27  |  -x64 -j 8 -l 3
OK       433500      46      37  |  -x64 -j 8 -l 4
OK       194679     194     107  |  -x64 -j 8 -l 5
OK       141971     369     201  |  -x64 -j 8 -l 6
OK       225890     346     189  |  -x64 -j 8 -l 7
OK       407558    2133    2082  |  -x64 -j 8 -l 8
OK       376449    3902    3748  |  -x64 -j 8 -l 9
OK       108691    1561    2181  |  -x64 -b 64m -j 8 -t TEXT+BWTS+SRT+ZRLT -e TPAQ
OK       242268    3809    3662  |  -x64 -b 256m -j 1 -t EXE+TEXT+RLT+UTF+PACK -e TPAQX
64.29user 7.75system 0:52.02elapsed 138%CPU (0avgtext+0avgdata 1461056maxresident)k
0inputs+0outputs (0major+4264342minor)pagefaults 0swaps
lør  3 jan 10:26:57 CET 2026
```
Compare the above with the similar test in the [kanzi_benchmark.sh](#kanzi_benchmarksh) section
and note that e.g. the above 369 milliseconds for `kanzi -c -x64 -j 8 -l 6` is very close to the
`0.370s` measured by the benchmark script.

## size-kanzi-algos-etc.sh

The main focus of the script is to test [kanzi](https://github.com/flanglet/kanzi-cpp) compression
of a given file with a lot of different combinations of transforms and entropy coders.

For comparison the script also tests compression with various other compression programs like
[xz](https://tukaani.org/xz/) and [zpaq](http://mattmahoney.net/dc/zpaq.html).

The script takes a single filename as argument and produces a long list of "size algorithm" pairs
where the size is the size of the input file when processed by the listed compression algorithm
(or `cat` = no compression).  The output should be redirected to a log file and sorted numerically
by size after the script has finished.

### Prerequisites

* [GNU Parallel](https://www.gnu.org/software/parallel/)
* [kanzi](https://github.com/flanglet/kanzi-cpp) (Go or Java version may work too if you name it "kanzi")
* [7za](http://p7zip.sourceforge.net/)
* Preferably many other compression programs too unless you live with errors from not having them:
	- [xz](https://tukaani.org/xz/)
	- [zpaq](http://mattmahoney.net/dc/zpaq.html)
	- [bzip3](https://github.com/kspalaiologos/bzip3)
	- [lrzip](https://github.com/ckolivas/lrzip)
	- [zstd](https://github.com/facebook/zstd)
	- [lz4](https://lz4.github.io/lz4/)
	- [bzip2](http://www.bzip.org/)
	- [gzip](https://www.gzip.org/)
	- [arj](http://arj.sourceforge.net/)

### Example 1 -- a default full run on enwik7

Here the script is first run on the exactly 10000000 bytes large
[enwik7](http://www.mattmahoney.net/dc/text.html) text file,
then the first 9-10 lines of output shown, finally start and end of numerically sorted output shown:
```
$ (date; size-kanzi-algos-etc.sh enwik7; date) > sizes-enwik7.log

$ head sizes-enwik7.log
søn  5 jan 11:36:48 CET 2025
 10000000 cat
  3685296 gzip -9
  4232930 lz4 -12
  2795014 zstd -19
  2793456 zstd --ultra -22
  2916026 bzip2
  2723036 xz
  2722096 xz -e
  2720256 xz -9e

$ sort -nr sizes-enwik7.log | (head -3;echo ...;tail)
 10002422 kanzi -x64 -b 64m -t BWT+BWTS+MM -e NONE
 10002418 kanzi -x64 -b 64m -t BWTS+BWT+MM -e NONE
 10002105 kanzi -x64 -b 64m -t BWT+MM+SRT -e NONE
...
  2102696 kanzi -x64 -b 64m -t MM+RLT+TEXT -e TPAQX
  2102696 kanzi -x64 -b 64m -t EXE+RLT+TEXT -e TPAQX
  2102689 kanzi -x64 -b 128m -l 9 -j 2
  2102513 kanzi -x64 -b 256m -l 9 -j 1
  2102512 kanzi -x64 -b 256m -t RLT+TEXT+PACK -e TPAQX -j 1
  2091358 zpaq a ... -m58 -t8
  2091358 zpaq a ... -m57 -t8
  2091358 zpaq a ... -m56 -t8
søn  5 jan 13:47:29 CET 2025
søn  5 jan 11:36:48 CET 2025
```

### Example 2 -- interrupted run with explicit NJOBS on a 191 MiB highly repetitive journalctl log file

In practice I didn't set NJOBS explicitly but I *could* have done so like this:
```
$ (date; NJOBS=8 size-kanzi-algos-etc.sh j-191M.txt; date) > sizes-j-191M.log
^C
^C$ cat sizes-j-191M.log | (head;echo ...;tail -5)
fre  3 jan 20:05:07 CET 2025
200114536 cat
 18213896 gzip -9
 23149150 lz4 -12
   937153 zstd -19
   909778 zstd --ultra -22
  3160640 bzip2
   960032 xz
   847904 xz -e
   828052 xz -9e
...
   949817 kanzi -x64 -b 64m -t RLT+BWTS+SRT -e CM
 15716301 kanzi -x64 -b 64m -t RLT+BWTS+EXE -e HUFFMAN
 14170436 kanzi -x64 -b 64m -t RLT+BWTS+EXE -e ANS0
   834872 kanzi -x64 -b 64m -t RLT+BWTS+SRT -e TPAQ
fre  3 jan 22:09:32 CET 202

$ sort -nr sizes-j-191M.log | grep -E 'zpaq|l 9'
  1787319 kanzi -x64 -b 256m -l 9 -j 1
   901245 zpaq a ... -m46
   791981 zpaq a ... -m53
   770750 kanzi -x64 -b 128m -l 9 -j 2
   627947 zpaq a ... -m56 -t8
   616508 kanzi -x64 -l 9 -j 1
   613962 zpaq a ... -m57 -t8
   605669 zpaq a ... -m58 -t8
   572075 kanzi -x64 -b 64m -l 9 -j 1
   555140 kanzi -x64 -b  96m -l 9 -j 4

$ sort -nr sizes-j-191M.log | tail
   502840 kanzi -x64 -b 256m -t TEXT+RLT+PACK -e TPAQX -j 1
   499447 kanzi -x64 -b 256m -t TEXT+RLT+LZP -e TPAQX -j 1
   496471 kanzi -x64 -b 256m -t TEXT+RLT+LZP+RLT -e TPAQX -j 1
   495052 kanzi -x64 -b 256m -t TEXT+RLT+PACK+RLT+LZP -e TPAQX -j 1
   495051 kanzi -x64 -b 256m -t TEXT+RLT+PACK+LZP -e TPAQX -j 1
   494040 kanzi -x64 -b 256m -t TEXT+RLT+PACK+LZP+RLT -e TPAQX -j 1
   490659 kanzi -x64 -b 256m -t TEXT+RLT+LZP+PACK -e TPAQX -j 1
   489820 kanzi -x64 -b 256m -t TEXT+RLT+LZP+PACK+RLT -e TPAQX -j 1
fre  3 jan 22:09:32 CET 2025
fre  3 jan 20:05:07 CET 2025

$ calc '1787319/616508;616508/605669;605669/555140;555140/489820'
	~2.89910106600400968033 ### kanzi level 9 w/ 256m blocks ~3 times larger than default 32m blocks!!!
	~1.01789591344447214568 ### kanzi level 9 w/  32m blocks ~1.8% larger than zpaq w/ 256m blocks
	~1.09102028317181251576 ### zpaq          w/ 256m blocks ~9% larger than kanzi -l 9 w/ 96m blocks
	~1.13335511004042301254 ### kanzi level 9 w/  96m blocks ~13% larger than best kanzi w/ 256m blocks
```
This example shows that in some cases kanzi is very sensitive to block size -- bigger is not always better --
but that with careful tuning it may beat even (untuned) zpaq considerably on size even though being
approximately a factor 10 faster than zpaq with these options.

### More test results

More test results and more detailed descriptions of the test files can be found in the [wiki](https://github.com/udickow/kanzi-testing-scripts/wiki).

## pareto-convex.pl

This is a Perl script that reads standard input or one or more numerically sorted text files given on the command line.
It prints out only a subset of the lines that begin with two integer or decimal notation numbers separated by whitespace.
The subset is the lines where the two numbers (x,y) are part of the convex hull of the lower
[Pareto front](https://en.wikipedia.org/wiki/Pareto_front).
Its main purpose is to be used by the
[kanzi_benchmark.sh](#kanzi_benchmarksh) script, expected to be in the PATH when running that.
But it may also be used stand-alone like this:
```
$ printf "2.0 5.0 much better y\n1.5 9.0 not on convex\n5.0 4.0 best y\n5.5 4.5 worse y\n0.5 12.0 best x but worse y\n0.5 10.0 best x (best y for that)\n"|LC_NUMERIC=C sort -sn
0.5 12.0 best x but worse y
0.5 10.0 best x (best y for that)
1.5 9.0 not on convex
2.0 5.0 much better y
5.0 4.0 best y
5.5 4.5 worse y

$ printf "2.0 5.0 much better y\n1.5 9.0 not on convex\n5.0 4.0 best y\n5.5 4.5 worse y\n0.5 12.0 best x but worse y\n0.5 10.0 best x (best y for that)\n"|LC_NUMERIC=C sort -sn|cut -d\  -f1-2|feedgnuplot --domain --points --terminal 'dumb 80,30' --exit --xmin 0 --ymin 3 --ymax 13 --unset grid --line

     +----------------------------------------------------------------------+
     |           +           +           +          +           +           |
     |                                                                      |
  12 |-+   A                                                              +-|
     |     *                                                                |
     |     *                                                                |
     |     *                                                                |
     |     *                                                                |
  10 |-+   A**                                                            +-|
     |        ******                                                        |
     |              ***A                                                    |
     |                  *                                                   |
     |                  *                                                   |
   8 |-+                 *                                                +-|
     |                   *                                                  |
     |                    *                                                 |
     |                    *                                                 |
     |                     *                                                |
   6 |-+                   *                                              +-|
     |                      *                                               |
     |                      *                                               |
     |                       A********                                      |
     |                                ******************           ***A     |
   4 |-+                                                ********A**       +-|
     |                                                                      |
     |           +           +           +          +           +           |
     +----------------------------------------------------------------------+
     0           1           2           3          4           5           6

$ printf "2.0 5.0 much better y\n1.5 9.0 not on convex\n5.0 4.0 best y\n5.5 4.5 worse y\n0.5 12.0 best x but worse y\n0.5 10.0 best x (best y for that)\n"|LC_NUMERIC=C sort -sn|./pareto-convex.pl
0.5 10.0 best x (best y for that)
2.0 5.0 much better y
5.0 4.0 best y
```
Note that point (1.5,9.0) is part of the Pareto front but not the convex part of it.

## kanzi_benchmark.sh

This is a refactored version of the [size-kanzi-algos-etc.sh](#size-kanzi-algos-etcsh) script,
[originally](https://github.com/udickow/kanzi-testing-scripts/pull/1) made by
[Andreas Reichel](https://github.com/manticore-projects?tab=repositories).
The main changes are:

* Only test kanzi and bzip3, not any other compressors
* Use 64m blocksize instead of 256m for the specialized transform chains like `EXE+TEXT+RLT+UTF+PACK`
* Beautify output with e.g. headings, rounding (up) sizes to [human readable (iec) format](https://www.man7.org/linux/man-pages/man1/numfmt.1.html#EXAMPLES)
* Measure approximate wall-clock time spent by each compression test, not only the compressed size
* Sort each set of parallel kanzi test results by compression percentage rounded to 2 decimals (so only an approximate sort)
* Add final analysis and recommendation section

### Prerequisites

* [GNU Parallel](https://www.gnu.org/software/parallel/)
* [kanzi](https://github.com/flanglet/kanzi-cpp) (Go or Java version may work too if you name it "kanzi")
* [bzip3](https://github.com/kspalaiologos/bzip3)

### Usage

```
$ ./kanzi_benchmark.sh --help
Usage: ./kanzi_benchmark.sh [OPTION]... FILE
Benchmark compression algorithms on given FILE with timing and ratio analysis.

Options:

   -j, --jobs=NJOBS
        Number of jobs (threads) for each bzip3/kanzi in general.
        Overrides the NJOBS environment variable.
        Default half the number of processors reported by nproc(1).

   -p, --programs=NPROGS
        Number of concurrent invocations of kanzi by GNU parallel.
        Default 1 to ensure reliable timings.

   -t, --threads=NTHREADS
        Number of threads (jobs) for each kanzi invoked by GNU parallel.
        Defaults to --jobs (NJOBS) value, giving fair comparison of
        timing with the initial non-parallel bzip3 and kanzi tests.

   -d, --depth=DEPTH
        Maximum number of transforms to combine in the loops over all
        possible transforms combined with all possible entropy codecs.
        Use 0 to skip all of those loops and only test special cases.
        Default depth is 3, the maximum allowed.

   -h, --help
        Display this help and exit.

Example:

  kanzi_benchmark.sh --jobs=8 -p8 -t 1 --depth 2 bashref.html
```
Options are parsed with [getopt(1)](https://manpages.ubuntu.com/manpages/trusty/en/man1/getopt.1.html)
and you thus have a great degree of freedom in using/omitting spaces or equal signs when giving options.

### Example -- run on the lzbench Silesia tar file with depth reduced to 2

Testing here on the [lzbench version](https://github.com/inikep/lzbench?tab=readme-ov-file#benchmarks) (211947520 bytes)
of [silesia.tar](https://github.com/DataCompression/corpus-collection/tree/main/Silesia-Corpus).
Note that this is a slightly different file than used in the
[wiki](https://github.com/udickow/kanzi-testing-scripts/wiki/Test-file-descriptions#silesia)
and that both are different from the 211957760 byte file currently used in the
[kanzi-cpp README](https://github.com/flanglet/kanzi-cpp?tab=readme-ov-file#silesiatar).

To be able to complete the test in a few hours instead of days, we reduce the depth from default 3 to 2.
We keep other options at default, set Linux to the Performance power profile and run it while not using
the laptop for other purposes.  This way we should get the most reliable timings, although still less
reproducible than if using lzbench.
The hardware is AMD Ryzen 9 5900HX (8 cores, 16 threads), overclocked above 4.7 GHz (max 4.89 GHz).
Software: Fedora 42 Linux w/ kernel 6.19.8.

The output below is slightly edited for this README but the timings are unchanged.
```
$ ll silesia.tar
-rw-r--r--. 1 ukd ukd 211947520 30 mar 22:31 silesia.tar

$ llw kanzi
lrwxrwxrwx. 1 root root 54 15 mar 13:53 /usr/local/bin/kanzi -> kanzi-2.5.1/kanzi-2.5.1-clang2018-znver3-nopic-lto-pgo

$ (date;\time ~/git/kanzi-testing-scripts/kanzi_benchmark.sh --depth 2 silesia.tar;date)>& ...silesia_lzbench_tar...out

$ grep -E -B11 -A30 '#|==' ...silesia_lzbench_tar...out
man 30 mar 22:34:15 CEST 2026
[INFO] Benchmarking compression algorithms
[INFO] Input file: silesia.tar (203MB)
[INFO] Parallel jobs generally: 8
[INFO] Parallel programs:       1
[INFO]   Threads for each:      8
[INFO] Transform loop depth:    2

  COMPRESSED       TIME     RATIO      SPEED ALGORITHM
------------ ---------- --------- ---------- ----------

# BZIP3 Variants
        46MB      4.69s    22.28%      43.13 bzip3
        46MB      4.93s    22.34%      41.01 bzip3 -b32
        46MB      7.64s    22.30%      26.46 bzip3 -b64
        46MB     11.93s    22.62%      16.94 bzip3 -b128
        47MB     19.64s    23.00%      10.29 bzip3 -b256

# KANZI Level Presets (Default Block Size)
        76MB     0.283s    37.43%     714.87 kanzi -l1
        66MB     0.173s    32.38%    1167.73 kanzi -l2
        62MB     0.409s    30.39%     493.62 kanzi -l3
        58MB     0.622s    28.53%     325.06 kanzi -l4
        52MB      1.90s    25.48%     106.65 kanzi -l5
        48MB      2.29s    23.36%      88.39 kanzi -l6
        46MB      3.55s    22.32%      56.86 kanzi -l7
        42MB     12.64s    20.40%      15.99 kanzi -l8
        40MB     19.49s    19.72%      10.36 kanzi -l9

# KANZI Level Presets (64MB Block Size)
        75MB     0.504s    36.84%     401.08 kanzi -b64m -l1
        66MB     0.439s    32.19%     459.93 kanzi -b64m -l2
        62MB     0.852s    30.36%     237.35 kanzi -b64m -l3
        60MB      1.21s    29.26%     166.73 kanzi -b64m -l4
        51MB      4.99s    25.03%      40.47 kanzi -b64m -l5
        47MB      5.24s    23.16%      38.58 kanzi -b64m -l6
        46MB      6.10s    22.29%      33.14 kanzi -b64m -l7
        41MB     19.92s    20.19%      10.14 kanzi -b64m -l8
        40MB     30.28s    19.63%       6.67 kanzi -b64m -l9

# KANZI Large Block Sizes (Level 9)
        44MB     20.36s    21.40%       9.92 kanzi -b1m -l9
        42MB     18.62s    20.33%      10.85 kanzi -b4m -l9
        41MB     18.07s    19.98%      11.18 kanzi -b8m -l9
        40MB     21.69s    19.73%       9.31 kanzi -b16m -l9
        40MB     19.65s    19.72%      10.28 kanzi -b32m -l9
        40MB     31.23s    19.63%       6.47 kanzi -b64m -l9
        40MB     40.61s    19.64%       4.97 kanzi -b96m -l9
        41MB     47.03s    19.83%       4.29 kanzi -b128m -l9
        40MB      1m10s    19.75%       2.87 kanzi -b256m -l9

# KANZI Specialized Transform Chains (64MB blocks)
        40MB     30.92s    19.63%       6.53 kanzi -tRLT -eTpaqx
        40MB     29.96s    19.68%       6.74 kanzi -tPACK -eTpaqx
        40MB     29.93s    19.70%       6.75 kanzi -tPACK+ZRLT+PACK -eTpaqx
        40MB     30.52s    19.63%       6.62 kanzi -tPACK+RLT -eTpaqx
        40MB     30.67s    19.63%       6.58 kanzi -tRLT+PACK -eTpaqx
        40MB     30.19s    19.63%       6.69 kanzi -tRLT+TEXT+PACK -eTpaqx
        40MB     29.61s    19.68%       6.82 kanzi -tRLT+PACK+LZP -eTpaqx
        40MB     29.60s    19.68%       6.82 kanzi -tRLT+PACK+LZP+RLT -eTpaqx
        40MB     29.74s    19.70%       6.79 kanzi -tTEXT+ZRLT+PACK -eTpaqx
        40MB     29.09s    19.68%       6.94 kanzi -tRLT+LZP+PACK+RLT -eTpaqx
        40MB     29.41s    19.75%       6.87 kanzi -tTEXT+ZRLT+PACK+LZP -eTpaqx
        40MB     30.47s    19.63%       6.63 kanzi -tTEXT+RLT+PACK -eTpaqx
        40MB     29.14s    19.68%       6.93 kanzi -tTEXT+RLT+LZP -eTpaqx
        40MB     29.21s    19.68%       6.91 kanzi -tTEXT+RLT+PACK+LZP -eTpaqx
        40MB     29.57s    19.68%       6.83 kanzi -tTEXT+RLT+LZP+RLT -eTpaqx
        40MB     29.91s    19.68%       6.75 kanzi -tTEXT+RLT+PACK+LZP+RLT -eTpaqx
        40MB     29.99s    19.68%       6.73 kanzi -tTEXT+RLT+LZP+PACK -eTpaqx
        40MB     29.72s    19.68%       6.80 kanzi -tTEXT+RLT+PACK+RLT+LZP -eTpaqx
        40MB     29.30s    19.68%       6.89 kanzi -tTEXT+RLT+LZP+PACK+RLT -eTpaqx
        40MB     30.59s    19.63%       6.60 kanzi -tTEXT+PACK+RLT -eTpaqx
        40MB     30.49s    19.63%       6.62 kanzi -tEXE+TEXT+RLT+UTF+PACK -eTpaqx
        40MB     30.97s    19.63%       6.52 kanzi -tEXE+TEXT+RLT+UTF+DNA -eTpaqx
        40MB     30.52s    19.63%       6.62 kanzi -tEXE+TEXT+RLT -eTpaqx
        40MB     31.26s    19.68%       6.46 kanzi -tEXE+TEXT -eTpaqx
        47MB     25.08s    22.96%       8.06 kanzi -tTEXT+BWTS+SRT+ZRLT -eTpaqx
        47MB     24.98s    22.96%       8.09 kanzi -tBWTS+SRT+ZRLT -eTpaqx
        49MB     26.60s    23.85%       7.59 kanzi -tTEXT+BWTS+MTFT+RLT -eTpaqx
        49MB     25.64s    23.85%       7.88 kanzi -tBWTS+MTFT+RLT -eTpaqx
        49MB     24.49s    23.85%       8.25 kanzi -tTEXT+BWT+MTFT+RLT -eTpaqx
        49MB     24.76s    23.85%       8.16 kanzi -tBWT+MTFT+RLT -eTpaqx

# KANZI Parallel Tests - 4-Transform BWT/BWTS Combinations
[INFO] Running 4-transform TEXT combinations (24 tests, possibly in parallel)
        47MB     17.56s    22.77%      11.51 kanzi -x64 -b 64m -t TEXT+BWT+SRT+ZRLT -e TPAQ
        47MB     19.21s    22.77%      10.52 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e TPAQ
        47MB      6.45s    22.82%      31.33 kanzi -x64 -b 64m -t TEXT+BWT+SRT+ZRLT -e CM
        47MB      7.96s    22.82%      25.39 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e CM
        47MB     17.79s    22.87%      11.35 kanzi -x64 -b 64m -t TEXT+BWT+SRT+RLT -e TPAQ
        47MB     19.44s    22.87%      10.39 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+RLT -e TPAQ
        47MB     22.53s    22.96%       8.97 kanzi -x64 -b 64m -t TEXT+BWT+SRT+ZRLT -e TPAQX
        47MB     24.60s    22.96%       8.21 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e TPAQX
        47MB     22.88s    23.02%       8.83 kanzi -x64 -b 64m -t TEXT+BWT+SRT+RLT -e TPAQX
        47MB     25.49s    23.02%       7.92 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+RLT -e TPAQX
        48MB      6.57s    23.55%      30.75 kanzi -x64 -b 64m -t TEXT+BWT+SRT+RLT -e CM
        48MB      7.83s    23.55%      25.80 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+RLT -e CM
        48MB     18.53s    23.57%      10.90 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+ZRLT -e TPAQ
        48MB     20.04s    23.57%      10.08 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+ZRLT -e TPAQ
        49MB     18.79s    23.75%      10.75 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+RLT -e TPAQ
        49MB     20.31s    23.75%       9.94 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+RLT -e TPAQ
        49MB     24.04s    23.76%       8.40 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+ZRLT -e TPAQX
        49MB     25.89s    23.76%       7.80 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+ZRLT -e TPAQX
        49MB      7.04s    23.77%      28.71 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+ZRLT -e CM
        49MB      8.50s    23.77%      23.78 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+ZRLT -e CM
        49MB     24.56s    23.85%       8.22 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+RLT -e TPAQX
        49MB     26.63s    23.85%       7.58 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+RLT -e TPAQX
        50MB      7.09s    24.44%      28.51 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+RLT -e CM
        50MB      8.44s    24.44%      23.95 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+RLT -e CM

# KANZI Parallel Tests - Single Transform + Entropy
[INFO] Running Single transform combinations (171 tests, possibly in parallel)
        40MB     30.21s    19.63%       6.69 kanzi -x64 -b 64m -t RLT -e TPAQX
        40MB     30.48s    19.68%       6.63 kanzi -x64 -b 64m -t NONE -e TPAQX
        40MB     30.84s    19.68%       6.55 kanzi -x64 -b 64m -t EXE -e TPAQX
        40MB     30.93s    19.68%       6.53 kanzi -x64 -b 64m -t UTF -e TPAQX
        40MB     31.16s    19.68%       6.48 kanzi -x64 -b 64m -t TEXT -e TPAQX
        40MB     31.40s    19.68%       6.43 kanzi -x64 -b 64m -t DNA -e TPAQX
        40MB     31.55s    19.68%       6.40 kanzi -x64 -b 64m -t PACK -e TPAQX
        40MB     30.14s    19.70%       6.70 kanzi -x64 -b 64m -t ZRLT -e TPAQX
        40MB     30.00s    19.73%       6.73 kanzi -x64 -b 64m -t LZP -e TPAQX
        41MB     31.58s    19.80%       6.40 kanzi -x64 -b 64m -t MM -e TPAQX
        41MB     19.92s    20.19%      10.14 kanzi -x64 -b 64m -t RLT -e TPAQ
        41MB     20.20s    20.23%      10.00 kanzi -x64 -b 64m -t ZRLT -e TPAQ
        41MB     19.68s    20.25%      10.26 kanzi -x64 -b 64m -t NONE -e TPAQ
        41MB     20.12s    20.25%      10.04 kanzi -x64 -b 64m -t EXE -e TPAQ
        41MB     20.14s    20.25%      10.03 kanzi -x64 -b 64m -t DNA -e TPAQ
        41MB     20.17s    20.25%      10.02 kanzi -x64 -b 64m -t TEXT -e TPAQ
        41MB     20.23s    20.25%       9.99 kanzi -x64 -b 64m -t UTF -e TPAQ
        41MB     20.38s    20.25%       9.91 kanzi -x64 -b 64m -t PACK -e TPAQ
        42MB     19.59s    20.32%      10.31 kanzi -x64 -b 64m -t LZP -e TPAQ
        42MB     20.00s    20.35%      10.10 kanzi -x64 -b 64m -t MM -e TPAQ
        46MB      7.01s    22.33%      28.82 kanzi -x64 -b 64m -t BWT -e CM
        46MB      8.66s    22.33%      23.35 kanzi -x64 -b 64m -t BWTS -e CM
        46MB     27.56s    22.72%       7.33 kanzi -x64 -b 64m -t BWT -e TPAQX
        46MB     29.50s    22.72%       6.85 kanzi -x64 -b 64m -t BWTS -e TPAQX
        47MB     19.89s    22.85%      10.16 kanzi -x64 -b 64m -t BWT -e TPAQ
        47MB     21.76s    22.85%       9.28 kanzi -x64 -b 64m -t BWTS -e TPAQ
        54MB      4.90s    26.33%      41.25 kanzi -x64 -b 64m -t BWT -e FPAQ
        54MB      6.44s    26.33%      31.37 kanzi -x64 -b 64m -t BWTS -e FPAQ
        57MB      1.89s    27.79%     106.79 kanzi -x64 -b 64m -t ROLZX -e NONE
--
       203MB      1.72s   100.00%     117.32 kanzi -x64 -b 64m -t RANK -e NONE
       203MB      2.58s   100.00%      78.45 kanzi -x64 -b 64m -t MTFT -e NONE
       203MB      4.18s   100.00%      48.38 kanzi -x64 -b 64m -t BWT -e NONE
       203MB      5.57s   100.00%      36.30 kanzi -x64 -b 64m -t BWTS -e NONE
       203MB     0.240s   100.00%     841.03 kanzi -x64 -b 64m -t NONE -e NONE
       203MB     0.251s   100.00%     804.23 kanzi -x64 -b 64m -t PACK -e NONE
       203MB     0.253s   100.00%     798.29 kanzi -x64 -b 64m -t DNA -e NONE
       203MB     0.267s   100.00%     755.68 kanzi -x64 -b 64m -t MM -e NONE
       203MB     0.271s   100.00%     744.94 kanzi -x64 -b 64m -t UTF -e NONE
       203MB     0.282s   100.00%     715.77 kanzi -x64 -b 64m -t EXE -e NONE

# KANZI Parallel Tests - Two Transform Combinations
[INFO] Running Two transform combinations (2160 tests, possibly in parallel)
        40MB     30.45s    19.63%       6.63 kanzi -x64 -b 64m -t RLT+PACK -e TPAQX
        40MB     30.52s    19.63%       6.62 kanzi -x64 -b 64m -t EXE+RLT -e TPAQX
        40MB     30.54s    19.63%       6.61 kanzi -x64 -b 64m -t RLT+EXE -e TPAQX
        40MB     30.55s    19.63%       6.61 kanzi -x64 -b 64m -t RLT+TEXT -e TPAQX
        40MB     30.67s    19.63%       6.58 kanzi -x64 -b 64m -t TEXT+RLT -e TPAQX
        40MB     31.28s    19.63%       6.46 kanzi -x64 -b 64m -t PACK+RLT -e TPAQX
        40MB     30.58s    19.64%       6.60 kanzi -x64 -b 64m -t RLT+ZRLT -e TPAQX
        40MB     29.12s    19.68%       6.94 kanzi -x64 -b 64m -t RLT+LZP -e TPAQX
	[...]
--
       203MB      8.63s   100.00%      23.42 kanzi -x64 -b 64m -t MTFT+BWTS -e NONE
       203MB     0.283s   100.00%     714.72 kanzi -x64 -b 64m -t MM+PACK -e NONE
       203MB     0.283s   100.00%     715.22 kanzi -x64 -b 64m -t PACK+MM -e NONE
       203MB     0.291s   100.00%     694.04 kanzi -x64 -b 64m -t EXE+PACK -e NONE
       203MB     0.300s   100.00%     673.78 kanzi -x64 -b 64m -t PACK+EXE -e NONE
       203MB     0.316s   100.00%     639.43 kanzi -x64 -b 64m -t EXE+MM -e NONE
       203MB     0.322s   100.00%     627.41 kanzi -x64 -b 64m -t MM+EXE -e NONE
       205MB      4.23s   101.27%      47.81 kanzi -x64 -b 64m -t BWT+MM -e NONE
       205MB      5.78s   101.27%      34.95 kanzi -x64 -b 64m -t BWTS+MM -e NONE
       205MB      1.67s   101.37%     120.83 kanzi -x64 -b 64m -t SRT+MM -e NONE

==========================================
FINAL ANALYSIS & RECOMMENDATIONS
==========================================

# From best via balanced to fastest (convex hull of Pareto front in double-logarithmic space)
        40MB     30.19s    19.63%       6.69 kanzi -tRLT+TEXT+PACK -eTpaqx
        40MB     19.49s    19.72%      10.36 kanzi -l9
        46MB      3.55s    22.32%      56.86 kanzi -l7
        48MB      2.29s    23.36%      88.39 kanzi -l6
        66MB     0.173s    32.38%    1167.73 kanzi -l2

📊 **BEST COMPRESSION RATIO:**
   Algorithm: kanzi -tRLT+TEXT+PACK -eTpaqx
   Size:      203MB → 40MB (19.63%)
   Time:      30.19s
   Speed:     6.69 MB/s
   Savings:   163MB (80.37% reduction)

⚖️  **MOST REASONABLE TRADE-OFF:**
   Algorithm: kanzi -l7
   Size:      203MB → 46MB (22.32%)
   Time:      3.55s
   Speed:     56.86 MB/s
   Savings:   158MB (77.68% reduction)

💡 **INSIGHTS:**
   • Tested 2417 compression configurations
   • 891 algorithms achieved >100 MB/s speed
   • 0 algorithms achieved <5% compression ratio
   • Balanced option provides good speed (>50 MB/s)
53950.72user 1850.12system 5:36:32elapsed 276%CPU (0avgtext+0avgdata 8968932maxresident)k
0inputs+616outputs (2major+1042322920minor)pagefaults 0swaps
tir 31 mar 04:10:48 CEST 2026
```
Note these two facts about the winner in compression ratio:

* `-x64 -b 64m` is implicit here; that's why it's about 1.5 times slower than the `-l9` with the 32 MiB default block size
* The TEXT and PACK transformations don't affect the size at all for this file so `-b 64m -t RLT -e TPAQX` might as well have been the winner except that random fluctuations made it 0.02s slower in this test

Note in general for all of the printed options, as of kanzi 2.5.1: kanzi is very unflexible in its option parsing.
It does _not_ use [getopt(3)](https://manpages.ubuntu.com/manpages/trusty/en/man3/getopt.3.html) and requires a space between the option flag and the value following it.  So both `-l7` and e.g. `-eTpaqx` will be ignored;
`-l 7` and `-e Tpaqx` (or e.g. `-e TPAQX`) must be used instead.
