#! /usr/bin/perl -w
# Author: Ulrik Dickow <u.dickow@gmail.com>, created 2026-06-05, updated later.
# Purpose: Output a pseudo-random sequence (same on every invocation except for lenght
#   and size of dictionary) of DSIZE different 4-byte chunks (with all constituent bytes
#   being different from each other) to demonstrate how in some cases multiple PACK
#   transformations by kanzi may be useful, i.e. -t PACK+PACK+PACK.
#   Happened to be useful for finding a bug in kanzi 2.5.3 too, and for making ANS1 shine.

use strict;

my ($nchunks, $dsize) = @ARGV;
$dsize = 4 unless defined $dsize;

die "Usage: $0 NCHUNKS [DSIZE]\n  where dictionary size DSIZE is in the interval 1-64\n"
    unless defined $nchunks and $nchunks =~ /^\+?\d+$/ and $dsize =~ /^\+?[1-9]\d?$/ and $dsize < 65;

srand(1); # Output the same sequence every time for reproducible testing

# Fill dictionary using multiple different bytes as building blocks.  Use very simple period 256
# pseudo-random generator to choose the byte sequence to make it harder for compression tools
# to see the regularity or to compress extra hard due to duplicated bytes within the dictionary.
my $n = 1;
sub nnext () { $n = (137*$n + 13) & 0xFF; return $n } # Bytes not repeated until exactly 256 steps later

my @dict = map { pack("L", (nnext << 24) + (nnext << 16) + (nnext << 8) + nnext) } (0..$dsize-1);
#printf("%08X\n", unpack("L",$_)) for (@dict);

for (my $i=0; $i<$nchunks; $i++) {
    print $dict[int(rand($dsize))];
}
