#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use File::Find;

my $total;
find(sub { $total += -s if -f }, '.');

say $total;
