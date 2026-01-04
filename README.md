# Kanzi testing scripts


This repository currently contains these bash scripts for testing and verifying [kanzi](https://github.com/flanglet/kanzi-cpp):

* [checksum-kanzi-d-filelist.sh](#checksum-kanzi-d-filelistsh)
* [recompress-old-kanzi-files.sh](#recompress-old-kanzi-filessh)
* [time-size-chk-kanzi-algos.sh](#time-size-chk-kanzi-algossh)
* [size-kanzi-algos-etc.sh](#size-kanzi-algos-etcsh)
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

## kanzi_benchmark.sh

This is a refactored version of the [size-kanzi-algos-etc.sh](#size-kanzi-algos-etcsh) script,
[originally](https://github.com/udickow/kanzi-testing-scripts/pull/1) made by
[Andreas Reichel](https://github.com/manticore-projects?tab=repositories).
The main changes are:

* Only test kanzi and bzip3, not any other compressors
* Use 64m blocksize instead of 256m for the specialized transform chains like `EXE+TEXT+RLT+UTF+PACK`
* Beautify output with e.g. headings, rounding (up) sizes to [human readable (iec) format](https://www.man7.org/linux/man-pages/man1/numfmt.1.html#EXAMPLES)
* Measure approximate wall-clock time spent by each compression test, not only the compressed size
    - Note that these timings may be *very* unreliable (sometimes several times too high) for the parallel tests
* Sort each set of parallel kanzi test results by compression percentage rounded to 2 decimals (so only an approximate sort)
* Add final analysis and recommendation section

### Prerequisites

* [GNU Parallel](https://www.gnu.org/software/parallel/)
* [kanzi](https://github.com/flanglet/kanzi-cpp) (Go or Java version may work too if you name it "kanzi")
* [bzip3](https://github.com/kspalaiologos/bzip3)

### Example 1 -- run on the Fedora 30 boot.log file with 8 parallel jobs

We test on the same
[private 24.1 MiB highly redundant Fedora 30 Linux /var/log/boot.log test file](https://github.com/udickow/kanzi-testing-scripts/wiki/Test-file-descriptions#boot30)
as in the [time-size-chk-kanzi-algos.sh](#time-size-chk-kanzi-algossh) section (the benchmark script rounds up the 24.1 MiB to `25MB`).
In the first run we use the default number of threads and jobs for the given hardware, 8 in this case.
Note that this gives much lower speeds for many of the the parallelly tested kanzi compressions than in the later, more fairly timed,
[NJOBS=1 run](#Example-2----single-threaded-non-parallel-run-on-the-Fedora-30-bootlog-file).
```
$ (date;\time kanzi_benchmark.sh boot-HOSTNAME-fc30big.log;date)> ...boot_HOSTNAME_fc30big...out 2>&1

$ grep -E -B10 -A25 '#|==' ...boot_HOSTNAME_fc30big...out
fre  2 jan 17:53:10 CET 2026
[INFO] Benchmarking compression algorithms
[INFO] Input file: boot-HOSTNAME-fc30big.log (25MB)
[INFO] Parallel jobs: 8

  COMPRESSED       TIME     RATIO      SPEED ALGORITHM
------------ ---------- --------- ---------- ----------

# BZIP3 Variants
       231KB     0.791s     0.93%      30.47 bzip3
       209KB      1.27s     0.84%      19.01 bzip3 -b32
       209KB      1.69s     0.84%      14.24 bzip3 -b64
       209KB      2.51s     0.84%       9.58 bzip3 -b128
       209KB      4.29s     0.84%       5.61 bzip3 -b256

# KANZI Level Presets (Default Block Size)
       2.6MB     0.025s    10.56%     954.58 kanzi -l1
       1.9MB     0.026s     7.57%     939.06 kanzi -l2
       1.4MB     0.047s     5.74%     511.94 kanzi -l3
       424KB     0.048s     1.71%     501.21 kanzi -l4
       191KB     0.189s     0.77%     127.61 kanzi -l5
       139KB     0.370s     0.56%      65.07 kanzi -l6
       221KB     0.347s     0.89%      69.39 kanzi -l7
       399KB      2.12s     1.61%      11.37 kanzi -l8
       368KB      3.86s     1.49%       6.23 kanzi -l9

# KANZI Level Presets (64MB Block Size)
       2.6MB     0.055s    10.45%     441.58 kanzi -b64m -l1
       1.8MB     0.061s     7.39%     394.63 kanzi -b64m -l2
       1.4MB     0.129s     5.74%     186.86 kanzi -b64m -l3
       359KB     0.130s     1.45%     184.73 kanzi -b64m -l4
       124KB     0.970s     0.50%      24.82 kanzi -b64m -l5
       111KB      1.11s     0.44%      21.63 kanzi -b64m -l6
       197KB     0.555s     0.79%      43.38 kanzi -b64m -l7
       394KB      3.20s     1.59%       7.53 kanzi -b64m -l8
       368KB      4.15s     1.49%       5.80 kanzi -b64m -l9

# KANZI Large Block Sizes (Level 9)
       468KB      1.65s     1.89%      14.60 kanzi -b1m -l9
       399KB      1.34s     1.61%      17.98 kanzi -b4m -l9
       386KB      1.66s     1.56%      14.50 kanzi -b8m -l9
       376KB      2.71s     1.52%       8.88 kanzi -b16m -l9
       368KB      3.94s     1.49%       6.11 kanzi -b32m -l9
       368KB      4.15s     1.49%       5.81 kanzi -b64m -l9
       368KB      4.24s     1.49%       5.68 kanzi -b96m -l9
       368KB      4.26s     1.49%       5.65 kanzi -b128m -l9
       368KB      4.32s     1.49%       5.58 kanzi -b256m -l9

# KANZI Specialized Transform Chains (64MB blocks)
       399KB      5.24s     1.61%       4.60 kanzi -tRLT -eTpaqx
       261KB      3.78s     1.05%       6.37 kanzi -tPACK -eTpaqx
       251KB      4.85s     1.01%       4.97 kanzi -tPACK+ZRLT+PACK -eTpaqx
       260KB      3.72s     1.05%       6.47 kanzi -tPACK+RLT -eTpaqx
       249KB      4.51s     1.00%       5.34 kanzi -tRLT+PACK -eTpaqx
       233KB      3.61s     0.94%       6.67 kanzi -tRLT+TEXT+PACK -eTpaqx
       243KB      3.04s     0.98%       7.93 kanzi -tRLT+PACK+LZP -eTpaqx
       243KB      3.21s     0.98%       7.50 kanzi -tRLT+PACK+LZP+RLT -eTpaqx
       235KB      3.64s     0.95%       6.61 kanzi -tTEXT+ZRLT+PACK -eTpaqx
       332KB      3.21s     1.34%       7.51 kanzi -tRLT+LZP+PACK+RLT -eTpaqx
       235KB      2.52s     0.94%       9.54 kanzi -tTEXT+ZRLT+PACK+LZP -eTpaqx
       235KB      3.52s     0.94%       6.84 kanzi -tTEXT+RLT+PACK -eTpaqx
       321KB      2.99s     1.29%       8.06 kanzi -tTEXT+RLT+LZP -eTpaqx
       235KB      2.57s     0.94%       9.37 kanzi -tTEXT+RLT+PACK+LZP -eTpaqx
       321KB      3.04s     1.29%       7.93 kanzi -tTEXT+RLT+LZP+RLT -eTpaqx
       235KB      2.58s     0.94%       9.32 kanzi -tTEXT+RLT+PACK+LZP+RLT -eTpaqx
       321KB      3.01s     1.29%       7.99 kanzi -tTEXT+RLT+LZP+PACK -eTpaqx
       235KB      2.57s     0.94%       9.35 kanzi -tTEXT+RLT+PACK+RLT+LZP -eTpaqx
       321KB      3.14s     1.29%       7.67 kanzi -tTEXT+RLT+LZP+PACK+RLT -eTpaqx
       234KB      3.67s     0.94%       6.56 kanzi -tTEXT+PACK+RLT -eTpaqx
       235KB      3.62s     0.94%       6.65 kanzi -tEXE+TEXT+RLT+UTF+PACK -eTpaqx
       368KB      4.13s     1.49%       5.83 kanzi -tEXE+TEXT+RLT+UTF+DNA -eTpaqx
       368KB      4.09s     1.49%       5.89 kanzi -tEXE+TEXT+RLT -eTpaqx
       369KB      4.17s     1.49%       5.77 kanzi -tEXE+TEXT -eTpaqx
       107KB      1.97s     0.43%      12.23 kanzi -tTEXT+BWTS+SRT+ZRLT -eTpaqx
       107KB      2.19s     0.43%      10.99 kanzi -tBWTS+SRT+ZRLT -eTpaqx
       108KB      2.03s     0.43%      11.87 kanzi -tTEXT+BWTS+MTFT+RLT -eTpaqx
       109KB      2.22s     0.43%      10.84 kanzi -tBWTS+MTFT+RLT -eTpaqx
       109KB      1.76s     0.43%      13.69 kanzi -tTEXT+BWT+MTFT+RLT -eTpaqx
       115KB      5.45s     0.46%       4.41 kanzi -tBWT+MTFT+RLT -eTpaqx

# KANZI Parallel Tests - 4-Transform BWT/BWTS Combinations
[INFO] Running 4-transform TEXT combinations (24 tests in parallel)
       107KB      3.14s     0.43%       7.68 kanzi -x64 -b 64m -t TEXT+BWT+SRT+ZRLT -e TPAQ
       107KB      3.66s     0.43%       6.58 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e TPAQX
       107KB      4.05s     0.43%       5.95 kanzi -x64 -b 64m -t TEXT+BWT+SRT+ZRLT -e TPAQX
       107KB      4.06s     0.43%       5.92 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e TPAQ
       107KB      5.12s     0.43%       4.70 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+RLT -e TPAQX
       108KB      2.72s     0.43%       8.85 kanzi -x64 -b 64m -t TEXT+BWT+SRT+ZRLT -e CM
       108KB      3.35s     0.43%       7.19 kanzi -x64 -b 64m -t TEXT+BWT+SRT+RLT -e TPAQ
       108KB      3.36s     0.43%       7.17 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+ZRLT -e TPAQ
       108KB      3.90s     0.43%       6.17 kanzi -x64 -b 64m -t TEXT+BWT+SRT+RLT -e TPAQX
       108KB      4.04s     0.43%       5.96 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+ZRLT -e TPAQX
       108KB      4.05s     0.43%       5.95 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e CM
       108KB      4.66s     0.43%       5.17 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+ZRLT -e TPAQ
       108KB      4.68s     0.43%       5.14 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+RLT -e TPAQ
       108KB      5.41s     0.43%       4.45 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+RLT -e TPAQX
       108KB      5.47s     0.43%       4.40 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+ZRLT -e TPAQX
       109KB      4.09s     0.43%       5.88 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+RLT -e TPAQX
       109KB      4.51s     0.43%       5.34 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+RLT -e TPAQ
       109KB      3.47s     0.44%       6.94 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+RLT -e TPAQ
       110KB      3.00s     0.44%       8.02 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+ZRLT -e CM
       110KB      4.24s     0.44%       5.67 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+ZRLT -e CM
       122KB      3.00s     0.49%       8.02 kanzi -x64 -b 64m -t TEXT+BWT+SRT+RLT -e CM
       122KB      4.39s     0.49%       5.48 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+RLT -e CM
       123KB      2.89s     0.49%       8.34 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+RLT -e CM
       123KB      4.04s     0.49%       5.95 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+RLT -e CM

# KANZI Parallel Tests - Single Transform + Entropy
[INFO] Running Single transform combinations (171 tests in parallel)
       115KB      6.71s     0.46%       3.58 kanzi -x64 -b 64m -t BWT -e TPAQX
       115KB      8.20s     0.46%       2.93 kanzi -x64 -b 64m -t BWTS -e TPAQX
       116KB      5.94s     0.46%       4.05 kanzi -x64 -b 64m -t BWT -e TPAQ
       116KB      8.24s     0.46%       2.92 kanzi -x64 -b 64m -t BWTS -e TPAQ
       122KB      3.68s     0.49%       6.54 kanzi -x64 -b 64m -t BWT -e CM
       122KB      5.68s     0.49%       4.23 kanzi -x64 -b 64m -t BWTS -e CM
       260KB      2.52s     1.05%       9.55 kanzi -x64 -b 64m -t BWT -e ANS1
       260KB      3.89s     1.05%       6.19 kanzi -x64 -b 64m -t BWTS -e ANS1
       261KB      2.66s     1.05%       9.06 kanzi -x64 -b 64m -t BWT -e FPAQ
       261KB      4.92s     1.05%       4.89 kanzi -x64 -b 64m -t BWTS -e FPAQ
       261KB     11.25s     1.05%       2.14 kanzi -x64 -b 64m -t PACK -e TPAQX
       310KB      6.13s     1.25%       3.93 kanzi -x64 -b 64m -t PACK -e TPAQ
       333KB      4.48s     1.34%       5.38 kanzi -x64 -b 64m -t LZP -e TPAQX
       358KB      3.07s     1.44%       7.85 kanzi -x64 -b 64m -t LZP -e TPAQ
       369KB      5.91s     1.49%       4.07 kanzi -x64 -b 64m -t TEXT -e TPAQX
       394KB      4.13s     1.59%       5.83 kanzi -x64 -b 64m -t TEXT -e TPAQ
       399KB      8.04s     1.61%       2.99 kanzi -x64 -b 64m -t RLT -e TPAQX
       400KB     0.478s     1.61%      50.41 kanzi -x64 -b 64m -t ROLZ -e TPAQ
       400KB      1.17s     1.62%      20.67 kanzi -x64 -b 64m -t ROLZ -e TPAQX
       401KB     0.073s     1.62%     328.32 kanzi -x64 -b 64m -t ROLZ -e HUFFMAN
       401KB     0.080s     1.62%     302.67 kanzi -x64 -b 64m -t ROLZ -e NONE
       401KB     0.103s     1.62%     233.15 kanzi -x64 -b 64m -t ROLZ -e CM
       402KB      6.83s     1.62%       3.52 kanzi -x64 -b 64m -t DNA -e TPAQX
       402KB      7.16s     1.62%       3.36 kanzi -x64 -b 64m -t ZRLT -e TPAQX
--
        25MB     0.061s   100.00%     395.26 kanzi -x64 -b 64m -t DNA -e NONE
        25MB     0.064s   100.00%     376.94 kanzi -x64 -b 64m -t ZRLT -e NONE
        25MB     0.073s   100.00%     327.93 kanzi -x64 -b 64m -t NONE -e NONE
        25MB     0.074s   100.00%     323.40 kanzi -x64 -b 64m -t UTF -e NONE
        25MB     0.076s   100.00%     318.76 kanzi -x64 -b 64m -t MM -e NONE
        25MB     0.082s   100.00%     292.54 kanzi -x64 -b 64m -t EXE -e NONE
        25MB     0.477s   100.00%      50.54 kanzi -x64 -b 64m -t RANK -e NONE
        25MB     0.611s   100.00%      39.41 kanzi -x64 -b 64m -t SRT -e NONE
        25MB     0.642s   100.00%      37.52 kanzi -x64 -b 64m -t MTFT -e NONE

# KANZI Parallel Tests - Two Transform Combinations
[INFO] Running Two transform combinations (2160 tests in parallel)
       111KB      5.47s     0.44%       4.40 kanzi -x64 -b 64m -t BWTS+RLT -e TPAQ
       112KB      2.53s     0.45%       9.53 kanzi -x64 -b 64m -t BWT+LZP -e CM
       112KB      2.89s     0.45%       8.32 kanzi -x64 -b 64m -t BWT+LZP -e TPAQ
       112KB      2.93s     0.45%       8.22 kanzi -x64 -b 64m -t BWT+RLT -e TPAQ
       112KB      3.82s     0.45%       6.31 kanzi -x64 -b 64m -t BWT+RLT -e TPAQX
       112KB      4.05s     0.45%       5.95 kanzi -x64 -b 64m -t BWT+LZP -e TPAQX
       112KB      4.79s     0.45%       5.03 kanzi -x64 -b 64m -t BWTS+LZP -e CM
       112KB      5.82s     0.45%       4.14 kanzi -x64 -b 64m -t BWTS+LZP -e TPAQ
       112KB      6.30s     0.45%       3.82 kanzi -x64 -b 64m -t BWTS+RLT -e TPAQX
       112KB      6.86s     0.45%       3.51 kanzi -x64 -b 64m -t BWTS+LZP -e TPAQX
       113KB      3.65s     0.45%       6.59 kanzi -x64 -b 64m -t PACK+BWT -e TPAQX
       113KB      4.55s     0.45%       5.28 kanzi -x64 -b 64m -t PACK+BWTS -e TPAQX
       113KB      5.29s     0.45%       4.55 kanzi -x64 -b 64m -t TEXT+BWT -e TPAQX
       113KB      7.36s     0.45%       3.27 kanzi -x64 -b 64m -t TEXT+BWTS -e TPAQX
       115KB      2.93s     0.46%       8.22 kanzi -x64 -b 64m -t PACK+BWT -e TPAQ
       115KB      3.83s     0.46%       6.28 kanzi -x64 -b 64m -t PACK+BWTS -e TPAQ
       115KB      4.67s     0.46%       5.15 kanzi -x64 -b 64m -t TEXT+BWT -e TPAQ
       115KB      5.56s     0.46%       4.33 kanzi -x64 -b 64m -t RLT+BWT -e TPAQ
       115KB      6.12s     0.46%       3.93 kanzi -x64 -b 64m -t RLT+BWT -e TPAQX
       115KB      6.19s     0.46%       3.89 kanzi -x64 -b 64m -t EXE+BWT -e TPAQX
       115KB      6.27s     0.46%       3.84 kanzi -x64 -b 64m -t MM+BWT -e TPAQX
       115KB      6.30s     0.46%       3.82 kanzi -x64 -b 64m -t TEXT+BWTS -e TPAQ
       115KB      6.56s     0.46%       3.67 kanzi -x64 -b 64m -t ZRLT+BWT -e TPAQX
       115KB      7.11s     0.46%       3.38 kanzi -x64 -b 64m -t BWT+EXE -e TPAQX
--
        25MB     0.646s   100.00%      37.29 kanzi -x64 -b 64m -t EXE+SRT -e NONE
        25MB     0.650s   100.00%      37.04 kanzi -x64 -b 64m -t SRT+EXE -e NONE
        25MB     0.650s   100.00%      37.06 kanzi -x64 -b 64m -t ZRLT+MTFT -e NONE
        25MB     0.654s   100.00%      36.85 kanzi -x64 -b 64m -t MTFT+MM -e NONE
        25MB     0.656s   100.00%      36.72 kanzi -x64 -b 64m -t MM+MTFT -e NONE
        25MB     0.656s   100.00%      36.73 kanzi -x64 -b 64m -t MTFT+TEXT -e NONE
        25MB     0.661s   100.00%      36.44 kanzi -x64 -b 64m -t MTFT+EXE -e NONE
        25MB     0.663s   100.00%      36.33 kanzi -x64 -b 64m -t EXE+MTFT -e NONE
        25MB     0.966s   100.00%      24.93 kanzi -x64 -b 64m -t SRT+RANK -e NONE

# KANZI Parallel Tests - Three Transform Combinations
[INFO] Running Three transform combinations (32400 tests in parallel)
       107KB      3.33s     0.43%       7.22 kanzi -x64 -b 64m -t BWT+SRT+ZRLT -e TPAQ
       107KB      4.03s     0.43%       5.98 kanzi -x64 -b 64m -t BWT+SRT+ZRLT -e TPAQX
       107KB      5.91s     0.43%       4.07 kanzi -x64 -b 64m -t BWTS+SRT+ZRLT -e TPAQ
       107KB      6.82s     0.43%       3.53 kanzi -x64 -b 64m -t BWTS+SRT+ZRLT -e TPAQX
       108KB      2.93s     0.43%       8.21 kanzi -x64 -b 64m -t BWT+SRT+RLT -e TPAQ
       108KB      3.85s     0.43%       6.25 kanzi -x64 -b 64m -t BWT+SRT+RLT -e TPAQX
       108KB      5.23s     0.43%       4.60 kanzi -x64 -b 64m -t BWTS+SRT+RLT -e TPAQ
       108KB      6.04s     0.43%       3.98 kanzi -x64 -b 64m -t BWTS+MTFT+ZRLT -e TPAQ
       108KB      6.23s     0.43%       3.86 kanzi -x64 -b 64m -t BWTS+SRT+RLT -e TPAQX
       108KB      7.10s     0.43%       3.39 kanzi -x64 -b 64m -t BWTS+MTFT+ZRLT -e TPAQX
       109KB      6.13s     0.43%       3.92 kanzi -x64 -b 64m -t BWTS+MTFT+RLT -e TPAQX
       109KB      2.78s     0.44%       8.66 kanzi -x64 -b 64m -t BWT+SRT+ZRLT -e CM
       109KB      5.30s     0.44%       4.54 kanzi -x64 -b 64m -t BWTS+MTFT+RLT -e TPAQ
       109KB      5.32s     0.44%       4.53 kanzi -x64 -b 64m -t BWTS+SRT+ZRLT -e CM
       109KB      6.09s     0.44%       3.95 kanzi -x64 -b 64m -t BWTS+RANK+ZRLT -e TPAQ
       109KB      7.07s     0.44%       3.40 kanzi -x64 -b 64m -t BWTS+RANK+ZRLT -e TPAQX
       110KB      2.20s     0.44%      10.93 kanzi -x64 -b 64m -t TEXT+BWT+LZP -e CM
       110KB      3.34s     0.44%       7.20 kanzi -x64 -b 64m -t TEXT+BWT+LZP -e TPAQX
       110KB      3.65s     0.44%       6.60 kanzi -x64 -b 64m -t TEXT+PACK+BWT -e TPAQX
       110KB      3.72s     0.44%       6.47 kanzi -x64 -b 64m -t TEXT+BWTS+LZP -e CM
       110KB      4.61s     0.44%       5.22 kanzi -x64 -b 64m -t TEXT+PACK+BWTS -e TPAQX
       110KB      5.35s     0.44%       4.50 kanzi -x64 -b 64m -t BWTS+RANK+RLT -e TPAQ
       110KB      5.42s     0.44%       4.44 kanzi -x64 -b 64m -t TEXT+BWTS+LZP -e TPAQX
       110KB      6.24s     0.44%       3.85 kanzi -x64 -b 64m -t BWTS+RANK+RLT -e TPAQX
--
        25MB     0.973s   100.00%      24.75 kanzi -x64 -b 64m -t MM+SRT+RANK -e NONE
        25MB     0.973s   100.00%      24.76 kanzi -x64 -b 64m -t ZRLT+SRT+RANK -e NONE
        25MB     0.975s   100.00%      24.70 kanzi -x64 -b 64m -t SRT+RANK+MM -e NONE
        25MB     0.978s   100.00%      24.61 kanzi -x64 -b 64m -t SRT+RANK+TEXT -e NONE
        25MB     0.978s   100.00%      24.64 kanzi -x64 -b 64m -t SRT+TEXT+RANK -e NONE
        25MB     0.989s   100.00%      24.34 kanzi -x64 -b 64m -t SRT+MM+RANK -e NONE
        25MB     0.989s   100.00%      24.35 kanzi -x64 -b 64m -t EXE+SRT+RANK -e NONE
        25MB     0.990s   100.00%      24.32 kanzi -x64 -b 64m -t SRT+RANK+EXE -e NONE
        25MB     0.993s   100.00%      24.26 kanzi -x64 -b 64m -t SRT+EXE+RANK -e NONE

==========================================
FINAL ANALYSIS & RECOMMENDATIONS
==========================================

📊 **BEST COMPRESSION RATIO:**
   Algorithm: kanzi -x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e TPAQ
   Size:      25MB → 107KB (0.43%)
   Time:      4.06s
   Speed:     5.92 MB/s
   Savings:   24MB (99.57% reduction)

⚖️  **MOST REASONABLE TRADE-OFF:**
   Algorithm: kanzi -l5
   Size:      25MB → 191KB (0.77%)
   Time:      0.189s
   Speed:     127.61 MB/s
   Savings:   24MB (99.23% reduction)

💡 **INSIGHTS:**
   • Tested 34817 compression configurations
   • 10189 algorithms achieved >100 MB/s speed
   • 15536 algorithms achieved <5% compression ratio
   • Excellent compression achieved (<3%)
   • Balanced option provides good speed (>50 MB/s)
72911.64user 7389.39system 2:47:04elapsed 801%CPU (0avgtext+0avgdata 8608824maxresident)k
496inputs+6000outputs (274major+2692800236minor)pagefaults 0swaps
fre  2 jan 20:40:15 CET 2026
```
This is an example of the much too high time measured in a parallel test: 4.06s reported for the
`-x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e TPAQ` case while only 1561 ms (1.56s) measured by kanzi itself in
the non-parallel [time-size-chk-kanzi-algos.sh](#time-size-chk-kanzi-algossh) script.
The approximately 1.55s is confirmed by manual timing:
```
$ \time kanzi -c -x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e TPAQ -j 1 -o none -v 4 -i boot-HOSTNAME-fc30big.log |grep time:
Compression time:   1543 ms
1.31user 0.22system 0:01.54elapsed 99%CPU (0avgtext+0avgdata 420360maxresident)k
0inputs+0outputs (0major+160215minor)pagefaults 0swaps
```
The reason for the slowdown is that memory hungry transforms (BWT, BWTS) and entropy coders (TPAQ, TPAQX)
compete for memory bandwidth.
This test shows that the SRT transform is slowed down by only a factor 1.09
while the BWT transform is slowed down by a factor 2.6:
```
$ echo 1 |\time parallel -j1 'echo $(kanzi -c -v 0 -x64 -b 64m -t SRT -e NONE -j 1 -o stdout -i boot-HOSTNAME-fc30big.log|wc -c)'
25260649 1
0.62user 0.04system 0:00.67elapsed 100%CPU (0avgtext+0avgdata 53996maxresident)k
0inputs+0outputs (0major+21963minor)pagefaults 0swaps

$ seq 1 8 |\time parallel -j8 'echo $(kanzi -c -v 0 -x64 -b 64m -t SRT -e NONE -j 1 -o stdout -i boot-HOSTNAME-fc30big.log|wc -c)'
25260649 1
25260649 2
25260649 5
25260649 6
25260649 3
25260649 7
25260649 8
25260649 4
4.72user 0.46system 0:00.73elapsed 708%CPU (0avgtext+0avgdata 53928maxresident)k
0inputs+0outputs (0major+122227minor)pagefaults 0swaps  ### Note 53 MiB max resident memory for SRT

$ echo 1 |\time parallel -j1 'echo $(kanzi -c -v 0 -x64 -b 64m -t BWT -e NONE -j 1 -o stdout -i boot-HOSTNAME-fc30big.log|wc -c)'
25260286 1
1.24user 0.08system 0:01.32elapsed 100%CPU (0avgtext+0avgdata 152740maxresident)k
0inputs+0outputs (0major+47232minor)pagefaults 0swaps

$ seq 1 8 |\time parallel -j8 'echo $(kanzi -c -v 0 -x64 -b 64m -t BWT -e NONE -j 1 -o stdout -i boot-HOSTNAME-fc30big.log|wc -c)'
25260286 5
25260286 4
25260286 2
25260286 1
25260286 8
25260286 7
25260286 6
25260286 3
26.00user 0.98system 0:03.52elapsed 766%CPU (0avgtext+0avgdata 152672maxresident)k
0inputs+0outputs (0major+324133minor)pagefaults 0swaps   ### Note 149 MiB max resident memory for BWT
```
Same test with BWTS instead of BWT gives a factor 3.7x (1.64s -> 6.11s) slowdown with 245 MiB max resident memory.

The slowdown factor for parallel jobs doesn't necessarily increase with increasing memory use, though:
testing `-t NONE -e TPAQX` gives only a factor 1.9 slowdown (5.35s -> 10.16s) in spite of 1.4 GiB mem used in that test.
Probably because TPAQX has a more regular/friendly memory access pattern than BWTS.

### Example 2 -- single-threaded non-parallel run on the Fedora 30 boot.log file

The most reliable timings are obtained with NJOBS=1 like here:
```
$ (date;NJOBS=1 \time kanzi_benchmark.sh boot-HOSTNAME-fc30big.log;date)> ...boot_HOSTNAME_fc30big_1t...out 2>&1

$ grep -E -B10 -A25 '#|==' ...boot_HOSTNAME_fc30big_1t...out
lør  3 jan 19:21:52 CET 2026
[INFO] Benchmarking compression algorithms
[INFO] Input file: boot-HOSTNAME-fc30big.log (25MB)
[INFO] Parallel jobs: 1

  COMPRESSED       TIME     RATIO      SPEED ALGORITHM
------------ ---------- --------- ---------- ----------

# BZIP3 Variants
       231KB     0.864s     0.93%      27.88 bzip3
       209KB     0.909s     0.84%      26.48 bzip3 -b32
       209KB     0.993s     0.84%      24.25 bzip3 -b64
       209KB      1.07s     0.84%      22.60 bzip3 -b128
       209KB      1.28s     0.84%      18.83 bzip3 -b256

# KANZI Level Presets (Default Block Size)
       2.6MB     0.051s    10.56%     473.41 kanzi -l1
       1.9MB     0.054s     7.57%     442.27 kanzi -l2
       1.4MB     0.137s     5.74%     175.24 kanzi -l3
       424KB     0.147s     1.71%     164.32 kanzi -l4
       191KB     0.627s     0.77%      38.45 kanzi -l5
       139KB     0.751s     0.56%      32.08 kanzi -l6
       221KB     0.496s     0.89%      48.54 kanzi -l7
       399KB      3.18s     1.61%       7.57 kanzi -l8
       368KB      3.84s     1.49%       6.26 kanzi -l9

# KANZI Level Presets (64MB Block Size)
       2.6MB     0.054s    10.45%     449.18 kanzi -b64m -l1
       1.8MB     0.062s     7.39%     390.65 kanzi -b64m -l2
       1.4MB     0.129s     5.74%     186.06 kanzi -b64m -l3
       359KB     0.130s     1.45%     185.05 kanzi -b64m -l4
       124KB     0.982s     0.50%      24.52 kanzi -b64m -l5
       111KB      1.08s     0.44%      22.27 kanzi -b64m -l6
       197KB     0.555s     0.79%      43.41 kanzi -b64m -l7
       394KB      3.18s     1.59%       7.58 kanzi -b64m -l8
       368KB      4.14s     1.49%       5.81 kanzi -b64m -l9

# KANZI Large Block Sizes (Level 9)
       468KB      6.31s     1.89%       3.81 kanzi -b1m -l9
       399KB      4.99s     1.61%       4.82 kanzi -b4m -l9
       386KB      4.30s     1.56%       5.60 kanzi -b8m -l9
       376KB      4.19s     1.52%       5.75 kanzi -b16m -l9
       368KB      3.88s     1.49%       6.21 kanzi -b32m -l9
       368KB      4.07s     1.49%       5.91 kanzi -b64m -l9
       368KB      4.13s     1.49%       5.83 kanzi -b96m -l9
       368KB      4.25s     1.49%       5.67 kanzi -b128m -l9
       368KB      4.29s     1.49%       5.61 kanzi -b256m -l9

# KANZI Specialized Transform Chains (64MB blocks)
       399KB      5.11s     1.61%       4.71 kanzi -tRLT -eTpaqx
       261KB      3.61s     1.05%       6.66 kanzi -tPACK -eTpaqx
       251KB      4.25s     1.01%       5.66 kanzi -tPACK+ZRLT+PACK -eTpaqx
       260KB      3.59s     1.05%       6.71 kanzi -tPACK+RLT -eTpaqx
       [...]
       109KB      1.75s     0.43%      13.77 kanzi -tTEXT+BWT+MTFT+RLT -eTpaqx
       115KB      5.37s     0.46%       4.48 kanzi -tBWT+MTFT+RLT -eTpaqx

# KANZI Parallel Tests - 4-Transform BWT/BWTS Combinations
[INFO] Running 4-transform TEXT combinations (24 tests in parallel)
       107KB      1.30s     0.43%      18.58 kanzi -x64 -b 64m -t TEXT+BWT+SRT+ZRLT -e TPAQ
       107KB      1.51s     0.43%      15.94 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e TPAQ
       107KB      1.71s     0.43%      14.04 kanzi -x64 -b 64m -t TEXT+BWT+SRT+ZRLT -e TPAQX
       107KB      1.93s     0.43%      12.47 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+RLT -e TPAQX
       107KB      1.93s     0.43%      12.50 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e TPAQX
       108KB      1.08s     0.43%      22.30 kanzi -x64 -b 64m -t TEXT+BWT+SRT+ZRLT -e CM
       108KB      1.30s     0.43%      18.51 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e CM
       108KB      1.31s     0.43%      18.45 kanzi -x64 -b 64m -t TEXT+BWT+SRT+RLT -e TPAQ
       108KB      1.32s     0.43%      18.26 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+ZRLT -e TPAQ
       108KB      1.53s     0.43%      15.74 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+ZRLT -e TPAQ
       108KB      1.53s     0.43%      15.77 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+RLT -e TPAQ
       108KB      1.72s     0.43%      13.99 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+ZRLT -e TPAQX
       108KB      1.72s     0.43%      14.03 kanzi -x64 -b 64m -t TEXT+BWT+SRT+RLT -e TPAQX
       108KB      1.94s     0.43%      12.44 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+ZRLT -e TPAQX
       108KB      1.95s     0.43%      12.32 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+RLT -e TPAQX
       109KB      1.54s     0.43%      15.60 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+RLT -e TPAQ
       109KB      1.75s     0.43%      13.79 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+RLT -e TPAQX
       109KB      1.32s     0.44%      18.18 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+RLT -e TPAQ
       110KB      1.10s     0.44%      21.92 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+ZRLT -e CM
       110KB      1.31s     0.44%      18.36 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+ZRLT -e CM
       122KB      1.09s     0.49%      22.05 kanzi -x64 -b 64m -t TEXT+BWT+SRT+RLT -e CM
       122KB      1.31s     0.49%      18.38 kanzi -x64 -b 64m -t TEXT+BWTS+SRT+RLT -e CM
       123KB      1.12s     0.49%      21.48 kanzi -x64 -b 64m -t TEXT+BWT+MTFT+RLT -e CM
       123KB      1.33s     0.49%      18.14 kanzi -x64 -b 64m -t TEXT+BWTS+MTFT+RLT -e CM

# KANZI Parallel Tests - Single Transform + Entropy
[INFO] Running Single transform combinations (171 tests in parallel)
       115KB      5.32s     0.46%       4.53 kanzi -x64 -b 64m -t BWT -e TPAQX
       115KB      5.63s     0.46%       4.27 kanzi -x64 -b 64m -t BWTS -e TPAQX
       116KB      4.68s     0.46%       5.15 kanzi -x64 -b 64m -t BWT -e TPAQ
       116KB      4.99s     0.46%       4.82 kanzi -x64 -b 64m -t BWTS -e TPAQ
       122KB      2.31s     0.49%      10.43 kanzi -x64 -b 64m -t BWT -e CM
       122KB      2.64s     0.49%       9.11 kanzi -x64 -b 64m -t BWTS -e CM
       260KB      1.27s     1.05%      18.99 kanzi -x64 -b 64m -t BWT -e ANS1
       260KB      1.60s     1.05%      15.09 kanzi -x64 -b 64m -t BWTS -e ANS1
       261KB      1.54s     1.05%      15.67 kanzi -x64 -b 64m -t BWT -e FPAQ
       261KB      1.86s     1.05%      12.94 kanzi -x64 -b 64m -t BWTS -e FPAQ
       261KB      3.59s     1.05%       6.70 kanzi -x64 -b 64m -t PACK -e TPAQX
       310KB      2.23s     1.25%      10.79 kanzi -x64 -b 64m -t PACK -e TPAQ
       333KB      3.14s     1.34%       7.66 kanzi -x64 -b 64m -t LZP -e TPAQX
       358KB      2.35s     1.44%      10.26 kanzi -x64 -b 64m -t LZP -e TPAQ
       369KB      4.15s     1.49%       5.80 kanzi -x64 -b 64m -t TEXT -e TPAQX
       394KB      3.18s     1.59%       7.57 kanzi -x64 -b 64m -t TEXT -e TPAQ
       399KB      5.08s     1.61%       4.74 kanzi -x64 -b 64m -t RLT -e TPAQX
       400KB     0.367s     1.61%      65.62 kanzi -x64 -b 64m -t ROLZ -e TPAQ
       400KB     0.859s     1.62%      28.05 kanzi -x64 -b 64m -t ROLZ -e TPAQX
       401KB     0.060s     1.62%     400.03 kanzi -x64 -b 64m -t ROLZ -e NONE
       401KB     0.063s     1.62%     383.58 kanzi -x64 -b 64m -t ROLZ -e HUFFMAN
       401KB     0.088s     1.62%     274.06 kanzi -x64 -b 64m -t ROLZ -e CM
       402KB      5.14s     1.62%       4.68 kanzi -x64 -b 64m -t DNA -e TPAQX
       402KB      5.14s     1.62%       4.68 kanzi -x64 -b 64m -t ZRLT -e TPAQX
--
        25MB     0.048s   100.00%     500.62 kanzi -x64 -b 64m -t NONE -e NONE
        25MB     0.053s   100.00%     454.70 kanzi -x64 -b 64m -t DNA -e NONE
        25MB     0.058s   100.00%     415.32 kanzi -x64 -b 64m -t UTF -e NONE
        25MB     0.059s   100.00%     408.11 kanzi -x64 -b 64m -t MM -e NONE
        25MB     0.060s   100.00%     404.49 kanzi -x64 -b 64m -t ZRLT -e NONE
        25MB     0.069s   100.00%     350.98 kanzi -x64 -b 64m -t EXE -e NONE
        25MB     0.453s   100.00%      53.17 kanzi -x64 -b 64m -t RANK -e NONE
        25MB     0.575s   100.00%      41.93 kanzi -x64 -b 64m -t SRT -e NONE
        25MB     0.601s   100.00%      40.07 kanzi -x64 -b 64m -t MTFT -e NONE

# KANZI Parallel Tests - Two Transform Combinations
[INFO] Running Two transform combinations (2160 tests in parallel)
       111KB      1.78s     0.44%      13.54 kanzi -x64 -b 64m -t BWTS+RLT -e TPAQ
       112KB      1.23s     0.45%      19.53 kanzi -x64 -b 64m -t BWT+LZP -e CM
       112KB      1.45s     0.45%      16.56 kanzi -x64 -b 64m -t BWT+RLT -e TPAQ
       112KB      1.51s     0.45%      15.94 kanzi -x64 -b 64m -t BWT+LZP -e TPAQ
       112KB      1.56s     0.45%      15.45 kanzi -x64 -b 64m -t BWTS+LZP -e CM
       112KB      1.85s     0.45%      13.03 kanzi -x64 -b 64m -t BWT+RLT -e TPAQX
       112KB      1.86s     0.45%      12.95 kanzi -x64 -b 64m -t BWTS+LZP -e TPAQ
       112KB      1.91s     0.45%      12.61 kanzi -x64 -b 64m -t BWT+LZP -e TPAQX
       112KB      2.18s     0.45%      11.07 kanzi -x64 -b 64m -t BWTS+RLT -e TPAQX
       112KB      2.30s     0.45%      10.48 kanzi -x64 -b 64m -t BWTS+LZP -e TPAQX
       113KB      3.07s     0.45%       7.85 kanzi -x64 -b 64m -t PACK+BWT -e TPAQX
       [...]
        25MB     0.626s   100.00%      38.49 kanzi -x64 -b 64m -t EXE+MTFT -e NONE
        25MB     0.628s   100.00%      38.37 kanzi -x64 -b 64m -t MM+MTFT -e NONE
        25MB     0.906s   100.00%      26.57 kanzi -x64 -b 64m -t SRT+RANK -e NONE
        25MB     0.959s   100.00%      25.11 kanzi -x64 -b 64m -t SRT+MTFT -e NONE
        25MB     0.964s   100.00%      24.98 kanzi -x64 -b 64m -t RANK+SRT -e NONE

# KANZI Parallel Tests - Three Transform Combinations
[INFO] Running Three transform combinations (32400 tests in parallel)
       107KB      1.46s     0.43%      16.50 kanzi -x64 -b 64m -t BWT+SRT+ZRLT -e TPAQ
       107KB      1.78s     0.43%      13.52 kanzi -x64 -b 64m -t BWTS+SRT+ZRLT -e TPAQ
       107KB      1.84s     0.43%      13.05 kanzi -x64 -b 64m -t BWT+SRT+ZRLT -e TPAQX
       107KB      2.15s     0.43%      11.19 kanzi -x64 -b 64m -t BWTS+SRT+ZRLT -e TPAQX
       108KB      1.47s     0.43%      16.43 kanzi -x64 -b 64m -t BWT+SRT+RLT -e TPAQ
       108KB      1.80s     0.43%      13.38 kanzi -x64 -b 64m -t BWTS+SRT+RLT -e TPAQ
       [...]
        25MB     0.991s   100.00%      24.31 kanzi -x64 -b 64m -t RANK+EXE+SRT -e NONE
        25MB     0.993s   100.00%      24.26 kanzi -x64 -b 64m -t RANK+SRT+EXE -e NONE

==========================================
FINAL ANALYSIS & RECOMMENDATIONS
==========================================

📊 **BEST COMPRESSION RATIO:**
   Algorithm: kanzi -x64 -b 64m -t TEXT+BWTS+SRT+ZRLT -e TPAQ
   Size:      25MB → 107KB (0.43%)
   Time:      1.51s
   Speed:     15.94 MB/s
   Savings:   24MB (99.57% reduction)

⚖️  **MOST REASONABLE TRADE-OFF:**
   Algorithm: kanzi -x64 -b 64m -t PACK+ROLZX+MM -e NONE
   Size:      25MB → 332KB (1.34%)
   Time:      0.143s
   Speed:     168.53 MB/s
   Savings:   24MB (98.66% reduction)

💡 **INSIGHTS:**
   • Tested 34817 compression configurations
   • 11796 algorithms achieved >100 MB/s speed
   • 15536 algorithms achieved <5% compression ratio
   • Excellent compression achieved (<3%)
   • Balanced option provides good speed (>50 MB/s)
40469.97user 4784.76system 13:28:24elapsed 93%CPU (0avgtext+0avgdata 1476008maxresident)k
0inputs+6008outputs (62major+2685089225minor)pagefaults 0swaps
søn  4 jan 08:50:16 CET 2026
```
Now we got 1.51s for the best compression ratio instead of 4.06s
and an entirely different recommendation.

Note that the recommendation is based on a rather arbitrary weighting between
compression ratio and speed and shouldn't be blindly accepted.

In the example, the recommended MM transformation is silly and just there due to
the limited precision of the measurements.
It's so fast that it doesn't make a measurable difference:
```
$ sync;for t in PACK+ROLZX+MM PACK+ROLZX;do for i in 1 2 3;do printf "$t:\t"; echo `kanzi -c -v 3 -x64 -b 64m -t $t -e NONE -j 1 -o none -i boot-HOSTNAME-fc30big.log|grep -E 'time:|Output size'`;done;echo;done
PACK+ROLZX+MM:	Compression time: 141 ms Output size: 339258
PACK+ROLZX+MM:	Compression time: 141 ms Output size: 339258
PACK+ROLZX+MM:	Compression time: 140 ms Output size: 339258

PACK+ROLZX:	Compression time: 141 ms Output size: 339258
PACK+ROLZX:	Compression time: 140 ms Output size: 339258
PACK+ROLZX:	Compression time: 140 ms Output size: 339258
```
