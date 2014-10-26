package TRL::Microarray::Spot;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.18';

require TRL::Microarray;


# an array_spot object contains all of the data 
# imported from the data_file for a single spot
# spot objects are identified by a spot index, derived from the data_file
{ package array_spot;

	sub new {
		my $class = shift;
		my $self = { };
		bless $self, $class;
		return $self;
	}
	# status indicates whether the spot was rejected or not
	sub spot_status {
		my $self = shift;
		@_	?	$self->{ _status } = shift
			:	$self->{ _status };
	}
	sub all_spot_values {
		my $self = shift;

		my $spot_index = $self->spot_index;
		my $block_row = $self->block_row;
		my $block_col = $self->block_col;
		my $spot_row = $self->spot_row;
		my $spot_col = $self->spot_col;
		my $x_pos = $self->x_pos;
		my $y_pos = $self->y_pos;
		my $diameter = $self->spot_diameter;
		my $spot_name = $self->feature_id;
		my $spot_id = $self->synonym_id;
		my $f_pixels = $self->spot_pixels;
		my $b_pixels = $self->bg_pixels;
		my $footprint = $self->footprint;
		my $flag = $self->flag_id;
		
		my $ch1_mean_f = $self->ch1_mean_f;
		my $ch1_median_f = $self->ch1_median_f;
		my $ch1_sd_f = $self->ch1_sd_f;
		my $ch1_mean_b = $self->ch1_mean_b;
		my $ch1_median_b = $self->ch1_median_b;
		my $ch1_sd_b = $self->ch1_sd_b;
		my $ch1b1sd = $self->ch1_b1sd;
		my $ch1b2sd = $self->channel1_quality;
		my $ch1fsat = $self->channel1_sat;
		
		my $ch2_mean_f = $self->ch2_mean_f;
		my $ch2_median_f = $self->ch2_median_f;
		my $ch2_sd_f = $self->ch2_sd_f;
		my $ch2_mean_b = $self->ch2_mean_b;
		my $ch2_median_b = $self->ch2_median_b;
		my $ch2_sd_b = $self->ch2_sd_b;
		my $ch2b1sd = $self->ch2_b1sd;
		my $ch2b2sd = $self->channel2_quality;
		my $ch2fsat = $self->channel2_sat;
		
		return	"	'$spot_index','$block_row','$block_col','$spot_row',
					'$spot_col','$x_pos','$y_pos','$spot_name','$spot_id','$f_pixels',
					'$b_pixels','$footprint','$flag','$ch1_mean_f','$ch1_median_f',
					'$ch1_sd_f','$ch1_mean_b','$ch1_median_b','$ch1_sd_b','$ch1b1sd',
					'$ch1b2sd','$ch1fsat','$ch2_mean_f','$ch2_median_f','$ch2_sd_f','$ch2_mean_b',
					'$ch2_median_b','$ch2_sd_b','$ch2b1sd','$ch2b2sd','$ch2fsat','$diameter' ";
	}
	sub ch2_b1sd {
		my $self = shift;
		@_	?	$self->{ _ch2_b1sd } = shift
			:	$self->{ _ch2_b1sd };
	}
	sub ch2_sd_b {
		my $self = shift;
		@_	?	$self->{ _ch2_sd_b } = shift
			:	$self->{ _ch2_sd_b };
	}
	sub ch2_median_b {
		my $self = shift;
		@_	?	$self->{ _ch2_median_b } = shift
			:	$self->{ _ch2_median_b };
	}
	sub ch2_mean_b {
		my $self = shift;
		@_	?	$self->{ _ch2_mean_b } = shift
			:	$self->{ _ch2_mean_b };
	}
	sub ch2_sd_f {
		my $self = shift;
		@_	?	$self->{ _ch2_sd_f } = shift
			:	$self->{ _ch2_sd_f };
	}
	sub ch2_median_f {
		my $self = shift;
		@_	?	$self->{ _ch2_median_f } = shift
			:	$self->{ _ch2_median_f };
	}
	sub ch2_mean_f {
		my $self = shift;
		@_	?	$self->{ _ch2_mean_f } = shift
			:	$self->{ _ch2_mean_f };
	}
	sub ch1_b1sd {
		my $self = shift;
		@_	?	$self->{ _ch1_b1sd } = shift
			:	$self->{ _ch1_b1sd };
	}
	sub ch1_sd_b {
		my $self = shift;
		@_	?	$self->{ _ch1_sd_b } = shift
			:	$self->{ _ch1_sd_b };
	}
	sub ch1_median_b {
		my $self = shift;
		@_	?	$self->{ _ch1_median_b } = shift
			:	$self->{ _ch1_median_b };
	}
	sub ch1_mean_b {
		my $self = shift;
		@_	?	$self->{ _ch1_mean_b } = shift
			:	$self->{ _ch1_mean_b };
	}
	sub ch1_sd_f {
		my $self = shift;
		@_	?	$self->{ _ch1_sd_f } = shift
			:	$self->{ _ch1_sd_f };
	}
	sub ch1_median_f {
		my $self = shift;
		@_	?	$self->{ _ch1_median_f } = shift
			:	$self->{ _ch1_median_f };
	}
	sub block_row {
		my $self = shift;
		@_	?	$self->{ _block_row } = shift
			:	$self->{ _block_row };
	}
	sub block_col {
		my $self = shift;
		@_	?	$self->{ _block_col } = shift
			:	$self->{ _block_col };
	}
	sub footprint {
		my $self = shift;
		@_	?	$self->{ _footprint } = shift
			:	$self->{ _footprint };
	}
	sub spot_row {
		my $self = shift;
		@_	?	$self->{ _spot_row } = shift
			:	$self->{ _spot_row };
	}
	sub spot_col {
		my $self = shift;
		@_	?	$self->{ _spot_col } = shift
			:	$self->{ _spot_col };
	}
	sub x_pos {
		my $self = shift;
		@_	?	$self->{ _x_pos } = shift
			:	$self->{ _x_pos };
	}
	sub y_pos {
		my $self = shift;
		@_	?	$self->{ _y_pos } = shift
			:	$self->{ _y_pos };
	}
	sub bg_pixels {
		my $self = shift;
		@_	?	$self->{ _bg_pixels } = shift
			:	$self->{ _bg_pixels };
	}
	sub ch1_mean_f {
		my $self = shift;
		@_	?	$self->{ _ch1_mean_f } = shift
			:	$self->{ _ch1_mean_f };
	}
	sub spot_index {
		my $self = shift;
		@_	?	$self->{ _spot_index } = shift
			:	$self->{ _spot_index };
	}
	sub feature_id {
		my $self = shift;
		@_	?	$self->{ _feature_id } = shift
			:	$self->{ _feature_id };
	}
	sub synonym_id {
		my $self = shift;
		@_	?	$self->{ _synonym_id } = shift
			:	$self->{ _synonym_id };
	}
	sub log2_ratio {
		my $self = shift;
		@_	?	$self->{ _log2_ratio } = shift
			:	$self->{ _log2_ratio };
	}
	sub channel1_signal {
		my $self = shift;
		@_	?	$self->{ _channel1_signal } = shift
			:	$self->{ _channel1_signal };
	}
	sub channel2_signal {
		my $self = shift;
		@_	?	$self->{ _channel2_signal } = shift
			:	$self->{ _channel2_signal };
	}
	sub channel1_snr {
		my $self = shift;
		@_	?	$self->{ _channel1_snr } = shift
			:	$self->{ _channel1_snr };
	}
	sub channel2_snr {
		my $self = shift;
		@_	?	$self->{ _channel2_snr } = shift
			:	$self->{ _channel2_snr };
	}
	sub channel1_quality {
		my $self = shift;
		@_	?	$self->{ _channel1_quality } = shift
			:	$self->{ _channel1_quality };
	}
	sub channel2_quality {
		my $self = shift;
		@_	?	$self->{ _channel2_quality } = shift
			:	$self->{ _channel2_quality };
	}
	sub channel1_sat {
		my $self = shift;
		@_	?	$self->{ _channel1_sat } = shift
			:	$self->{ _channel1_sat };
	}
	sub channel2_sat {
		my $self = shift;
		@_	?	$self->{ _channel2_sat } = shift
			:	$self->{ _channel2_sat };
	}
	sub spot_diameter {
		my $self = shift;
		@_	?	$self->{ _spot_diameter } = shift
			:	$self->{ _spot_diameter };
	}
	sub spot_pixels {
		my $self = shift;
		@_	?	$self->{ _spot_pixels } = shift
			:	$self->{ _spot_pixels };
	}
	sub flag_id {
		my $self = shift;
		@_	?	$self->{ _flag_id } = shift
			:	$self->{ _flag_id };
	}
	sub other_fields {
		my $self = shift;
		my $field = shift;
		unless (defined $self->{ _other_fields }){
			$self->{ _other_fields } = { };
		}
		my $hOthers = $self->{ _other_fields };
		if (@_){
			$hOthers->{ $field } = shift;
		} else {
			$hOthers->{ $field };
		}
	}
}

1;


__END__

=head1 NAME

TRL::Microarray::Spot - A Perl module for creating and manipulating microarray spot objects

=head1 SYNOPSIS

	use TRL::Microarray;

	my $spot = array_spot->new('spot 1');
	$spot->channel1_signal(32423);
	$spot->channel2_signal(29478);

=head1 DESCRIPTION

TRL::Microarray::Spot is an object-oriented Perl module for creating and manipulating microarray spot objects. Spot data is imported from a TRL::Microarray::Microarray_File::Data_File object and retrieved by calling any of the methods described below. 

=head1 METHODS

=over

=item spot_index

As defined in the data file, and/or the order the spot appeared in the data file

=item feature_id and synonym_id

Usually the 'Name' and 'ID' fields of the data file, respectively

=item channel1_signal and channel2_signal

The background-subtracted signals (mean signal-median background)

=item channel1_snr and channel2_snr

Signal to noise ratio. For the ScanArray format, this is median signal/background SD. For most other formats this is signal/background

=item channel1_quality and channel2_quality

For the ScanArray format, this is the percentage of pixels with signal more than 2 standard deviations above background

=item channel1_sat and channel2_sat

The percentage of pixels with a saturated signal

=item spot_diameter

Units are usually in microns

=item spot_pixels

The number of pixels depends on the scan resolution. This is usually defined in the data file header information from a scan

=item flag_id

If there is a flag associated with the spot, returns that number

=item spot_status

Indicates whether the spot was rejected by QC criteria (0=failed, 1=passed)

=back

=head1 SEE ALSO

TRL::Microarray, TRL::Microarray::Feature, TRL::Microarray::Microarray_File, TRL::Microarray::Microarray_File::Data_File

=head1 AUTHOR

Christopher Jones, Translational Research Laboratories, Institute for Women's Health, University College London.

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
