#! /usr/bin/perl -w
# -*- indent-tabs-mode: nil; -*-
# Copyright 2026 Ulrik Dickow <u.dickow@gmail.com>
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
# Purpose: Print the input lines that are part of the convex hull of the Pareto frontier
#   of the 2D points (x,y).  Input lines are assumed to be of this form (silently throwing away all
#   lines that don't match this):
#
#      x y anything after this
#
#   where x and y are floating point numbers (dot as decimal separator) and the input lines
#   are sorted by x from lowest to highest x.

use strict;
use Math::BigFloat; # https://www.w3tutorials.net/blog/is-there-an-inf-constant-in-perl/

my $neg_inf = Math::BigFloat->binf('-'); # Negative infinity, makes loop to ensure convexity simpler

my @px;    # x values of current potential Pareto points
my @py;    # y values of -"-
my @pline; # Full lines of current potential Pareto set (all 3 arrays have same # of elements)
my @dprev; # dy/dx to previous point (dprev[i] = (py[i] - py[i-1]) / (px[i] - px[i-1])).
           # At all times for all i>=1 this is true: dprev[i] >= dprev[i-1] (convex condition).
sub ppush { # Store potential Pareto candidate
    my ($x, $y, $line, $delta) = @_;
    push @px, $x;
    push @py, $y;
    push @pline, $line;
    push @dprev, $delta;
}

sub ppop { # Throw away most recent Pareto candidate (highest x)
    pop @px; pop @py; pop @pline; pop @dprev;
}

while (<>) {
    next unless /^\s*([-+]?\d+(?:\.\d+))\s+([-+]?\d+(?:\.\d+))/;
    my ($x, $y) = ($1, $2);
    if (!@px) { # This is the first matching line.  Save as first candidate point.
        ppush $x, $y, $_, $neg_inf;
        next;
    }
    my $i = $#px; # Just for convenience, index of latest element in all our Pareto arrays
    die "Input must be sorted numerically!" if $x < $px[$i];
    next if $y >= $py[$i]; # As we meet same or higher x values, only lower y values are relevant
    # From now on we know current point must be saved.  But it may be so good that it should
    # replace one or more of the previous points (that should thus be popped first).
    if ($x == $px[$i]) {
        # Same x but improved (lower) y so must definitely replace latest point.
        # _May_ also replace one or more before that but they all have lower x (if they exist).
        ppop; $i--;
        if ($i < 0) {
            # There was only 1 point, so just store our new with better y and go to next line
            ppush $x, $y, $_, $neg_inf;
            next;
        }
    }
    my $delta = ($y - $py[$i]) / ($x - $px[$i]);
    # Pop away previous candidates until the convexity condition is ensured
    while ($delta < $dprev[$i]) {
        ppop; $i--;
        $delta = ($y - $py[$i]) / ($x - $px[$i]);
    }
    ppush $x, $y, $_, $delta;
}
print @pline;
