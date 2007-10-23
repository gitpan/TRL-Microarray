package TRL::Microarray::Microarray_File::BlueFuse;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.02';



{ package bluefuse_file;

	require TRL::Microarray::Microarray_File::Data_File;

	our @ISA = qw( data_file );

	# setter for { _spot_data }, { _data_fields } and { _header_info }
	sub sort_data {
		my $self = shift;
		my $aaData = shift;
		$self->set_header_info($aaData);
		$self->set_data_fields(shift @$aaData);
		$self->{ _spot_data } = $aaData;		# all the numbers
		$self->{ _spot_count } = scalar @$aaData;
	}
	
	# information about the scan
	sub set_header_info {
		my $self = shift;
		my $aaData = shift;
		my $hHeader_Info = { };
		my ($flags,$qc);
		
		while (my $aRow = shift @$aaData){
		
			next unless (@$aRow);
			if ($$aRow[0] eq 'ROW'){
				unshift(@$aaData,$aRow);	
				last;
			} elsif ($$aRow[0] =~ /#/){
				next;
			} elsif ($$aRow[0] =~ /^Created by/){
				my $value = $$aRow[0];
				$value =~ s/Created by //;
				$hHeader_Info->{ VERSION } = $value;
			} elsif ($$aRow[0] =~ /ARRAY QC START:/){
				$qc++;
			} elsif ($$aRow[0] =~ /ARRAY QC END:/){
				$qc = undef;
			} elsif ($qc) {
				if ($$aRow[0] eq 'Confidence Flags (%)'){
					$flags++;
				} elsif ($flags){
					$hHeader_Info->{ 'Confidence Flags (%)' } = {
						A => $$aRow[2], 
						B => $$aRow[3],
						C => $$aRow[4],
						D => $$aRow[5],
						E => $$aRow[6]
					};
					$flags = undef;
				} else {
					$hHeader_Info->{ $$aRow[0] } = $$aRow[3];
				}
			} else {
				my ($key,$value) = split(/: /,$$aRow[0]);
				if ($key eq 'CONFIDENCE FLAGS'){
					my @aFlag_Estimates = split(/, /,$value);
					my $hFlag_Ranges = { };
					for my $flag_range (@aFlag_Estimates){
						my ($start,$flag,$end) = split(/ < /,$flag_range);
						$hFlag_Ranges->{ $flag } = [$start,$end];
					}
					$value = $hFlag_Ranges;
				}
				$hHeader_Info->{ $key } = $value;
			}	
		}
		$self->{ _header_info } = $hHeader_Info;
	}
	
	### header info getters ###
	
	#Êbarcode not saved in bluefuse file
	#Êhave to guess from data_file method
	sub barcode {
		my $self = shift;
		$self->guess_barcode;
	}
	sub analysis_software {
		my $self = shift;
		$self->get_header_info('VERSION');
	}
	sub build {
		my $self = shift;
		$self->get_header_info('BUILD');
	}
	sub date {
		my $self = shift;
		$self->get_header_info('DATE');
	}
	sub experiment {
		my $self = shift;
		$self->get_header_info('EXPERIMENT');
	}
	sub channel1_image_file {
		my $self = shift;
		$self->get_header_info('CH1');
	}
	sub channel2_image_file {
		my $self = shift;
		$self->get_header_info('CH2');
	}
	sub frame_ch1 {
		my $self = shift;
		$self->get_header_info('FRAME CH1');
	}
	sub frame_ch2 {
		my $self = shift;
		$self->get_header_info('FRAME CH2');
	}
	sub gal_file {
		my $self = shift;
		$self->get_header_info('GAL');
	}
	sub clone_file {
		my $self = shift;
		$self->get_header_info('CLONEFILE');
	}
	sub clone_text {
		my $self = shift;
		$self->get_header_info('CLONETEXT');
	}
	sub confidence_flag_range {
		my $self = shift;
		my $hFlags = $self->get_header_info('CONFIDENCE FLAGS');
		if(@_){
			my $flag = shift;
			if (wantarray()) {
				return @{ $hFlags->{ $flag } };
			} else {
				return $hFlags->{ $flag };
			}
		} elsif (wantarray()) {
			return ($$hFlags{E}[0],$$hFlags{E}[1],$$hFlags{D}[1],$$hFlags{C}[1],$$hFlags{B}[1],$$hFlags{A}[1]);
		} else {
			return $hFlags;	# a hashref
		}
	}
	sub replicate_field {
		my $self = shift;
		return $self->get_header_info('IDENTIFY REPLICATES BY');
	}
	sub confidence_flag_percen {
		my $self = shift;
		my $hFlags = $self->get_header_info('Confidence Flags (%)');
		if(@_){
			my $flag = shift;
			return $hFlags->{ $flag };
		} elsif (wantarray()) {
			return ($hFlags->{A},$hFlags->{B},$hFlags->{C},$hFlags->{D},$hFlags->{E});
		} else {
			return $hFlags;	# a hashref
		}
	}
	sub log_ratio_sd {
		my $self = shift;
		return $self->get_header_info('SD of Log2Ratio');
	}
	sub rep_median_sd {
		my $self = shift;
		return $self->get_header_info('Median SD Between Replicates');
	}
	sub mean_ch1_amp {
		my $self = shift;
		return $self->get_header_info('Mean Ch1 Spot Amplitude');
	}
	sub mean_ch2_amp {
		my $self = shift;
		return $self->get_header_info('Mean Ch2 Spot Amplitude');
	}
	sub sbr_ch1 {
		my $self = shift;
		return $self->get_header_info('SBR Ch1');
	}
	sub sbr_ch2 {
		my $self = shift;
		return $self->get_header_info('SBR Ch2');
	}
	
	### data file fields ###	
	sub return_data {
		my $self = shift;
		my $aaData = $self->spot_data;
		return $aaData->[shift][shift];
	}
	sub spot_index {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('SPOTNUM'));
	}
	sub block_row {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('ROW'));
	}
	sub block_col {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('COL'));
	}
	sub spot_row {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('SUBGRIDROW'));
	}
	sub spot_col {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('SUBGRIDCOL'));
	}
	sub block {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('BLOCK'));
	}
	sub feature_id {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('NAME'));
	}
	sub synonym_id {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('ID'));
	}
	sub confidence {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('CONFIDENCE'));
	}
	sub flag_id {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('FLAG'));
	}
	sub man_excl {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('MAN EXCL'));
	}
	sub auto_excl {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('AUTO EXCL'));
	}
	sub ch1_mean_f {
		my $self = shift;
		$self->channel1_signal(shift);
	}
	sub ch2_mean_f {
		my $self = shift;
		$self->channel2_signal(shift);
	}
	sub channel1_signal {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('AMPCH1'));
	}
	sub channel2_signal {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('AMPCH2'));
	}
	sub ch1_median_b {
		1
	}
	sub ch2_median_b {
		1
	}
	sub ratio_ch1ch2 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('RATIO CH1/CH2'));
	}
	sub ratio_ch2ch1 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('RATIO CH2/CH1'));
	}
	sub log2ratio_ch1ch2 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG2RATIO CH1/CH2'));
	}
	sub log2ratio_ch2ch1 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG2RATIO CH2/CH1'));
	}
	sub log10ratio_ch1ch2 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG10RATIO CH1/CH2'));
	}
	sub log10ratio_ch2ch1 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG10RATIO CH2/CH1'));
	}
	sub sumch1ch2 {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('SUM'));
	}
	sub log2sum {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG2SUM'));
	}
	sub log10sum {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG10SUM'));
	}
	sub product {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('PRODUCT'));
	}
	sub log2product {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG2PRODUCT'));
	}
	sub log10product {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('LOG10PRODUCT'));
	}
	sub y_pos {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('PELROW'));
	}
	sub x_pos {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('PELCOL'));
	}
	sub channel1_quality {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('P ON CH1'));
	}
	sub channel2_quality {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('P ON CH2'));
	}
	sub spot_diameter {
		my $self = shift;
		return 2*($self->return_data(shift,$self->get_column_id('RADIUS')));
	}
	sub uniformity {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('UNIFORMITY'));
	}
	sub circularity {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('CIRCULARITY'));
	}
	sub grid_offset {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('GRID OFFSET'));
	}
	sub quality {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('QUALITY'));
	}
	sub chromosome {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('CHROMOSOME'));
	}
	sub position {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('POSITION'));
	}
	sub cyto_locn {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('CYTO LOCN'));
	}
	sub display {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('DISPLAY'));
	}
	
	sub omim {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('OMIM'));
	}
	
	sub disease {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('DISEASE'));
	}
	sub gc_content {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('GC CONTENT'));
	}	
	sub bad_flags {
		{ 'C'=>'1', 'D'=>'1', 'E'=>'1' };
	}
}

1;

__END__

=head1 NAME

TRL::Microarray::Microarray_File::BlueFuse - A Perl module for managing BlueFuse 'output' files

=head1 SYNOPSIS

	use TRL::Microarray::Microarray_File::BlueFuse;
	my $data_file = bluefuse_file->new("/file.csv");

=head1 DESCRIPTION

TRL::Microarray::Microarray_File::BlueFuse is an object-oriented Perl module for managing microarray files created by 'BlueFuse' software. It inherits from TRL::Microarray::Microarray_File, and maps data fields in a BlueFuse 'output' data file to those used by TRL::Microarray::Microarray_File::Data_File. 

=head1 METHODS

=head2 General Header Information

=over

=item analysis_software, build, experiment, frame_ch1, frame_ch2, gal_file, clone_file, clone_text, channel1_image_file, channel2_image_file

These methods all return the relevant header information as a scalar.

=item confidence_flag_range, confidence_flag_range($flag)

Returns the confidence estimate range for each confidence flag. Passing a flag as an argument returns ($start,$end) for that flag. Alternatively if a list is requested it will return each division, starting at 0 and ending at 1, else will return a hashref of keys A to E and the range as an arrayref [$start,$end]. 

=item barcode

Odd - BlueFuse does not return the barcode in the file header. So it has to guess it using the data_file method guess_barcode()

=back

=head2 Array QC Header Information

=over

=item confidence_flag_percen, confidence_flag_percen($flag)

Returns the percentage of spots with each confidence flag. Passing a flag as an argument returns only the value for that flag. Alternatively if a list is requested it will return a list of values for flags A to E, else will return a hashref of keys A to E and their respective flag values.

=item log_ratio_sd, rep_median_sd, mean_ch1_amp, mean_ch2_amp, sbr_ch1, sbr_ch2

These methods all return the relevant header information as a scalar.

=back

=head2 Spot Information

Pass a spot index to any of these methods to retrieve the relevant value for that spot.

=over

=item block_row, block_col, spot_row, spot_col

The ROW, COL, SUBGRIDROW and SUBGRIDCOL columns - describing the grid location of the spot. 

=item feature_id, synonym_id

The NAME and ID columns - the unique identifiers of each spotted feature.

=item confidence, flag_id, man_excl, auto_excl

The CONFIDENCE, FLAG, MAN EXCL and AUTO EXCL columns. Flag confidence estimates can be returned separately (see above).  

=item ch1_mean_f, ch2_mean_f, channel1_signal, channel2_signal

Actually return the AMPCH1 and AMPCH2 columns - the spot signal. The ch_mean_f methods are provided for compatibility with other modules which calculate signal and background separately, and in which the calculated signal is returned using the methods channel1_signal and channel2_signal. As a result, the methods ch1_median_b and ch2_median_b are also provided in this module, but will always return '0'. However, other values for signal and background (such as snr, median_f, sd_f, mean_b and sd_b) are not returned and will generate an error.

=item x_pos, y_pos

The PELROW and PELCOL columns - the spot coordinates, returning the top/left position of the spot. 

=item channel1_quality, channel2_quality

The P ON CH1 and P ON CH2 columns - estimates of the baysian probability that a biological signal is present in each channel

=item spot_diameter, uniformity, circularity, grid_offset, quality

The 2*(RADIUS), UNIFORMITY, CIRCULARITY, QUALITY and GRID OFFSET columns.

=back

=head1 SEE ALSO

TRL::Microarray, TRL::Microarray::Microarray_File, TRL::Microarray::Microarray_File::Data_File

=head1 AUTHOR

Christopher Jones, Translational Research Laboratories, Institute for Women's Health, University College London.

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
