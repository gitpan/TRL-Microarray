#!/usr/bin/perl -w

use strict;


use Test::More tests => 6;
BEGIN { use_ok('TRL::Microarray') };
BEGIN { use_ok('TRL::Microarray::Feature') };
BEGIN { use_ok('TRL::Microarray::Spot') };
BEGIN { use_ok('TRL::Microarray::Image') };
BEGIN { use_ok('TRL::Microarray::Microarray_File::GenePix') };
BEGIN { use_ok('TRL::Microarray::Microarray_File::Agilent') };

