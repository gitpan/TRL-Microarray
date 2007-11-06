package TRL::Microarray::Microarray_File::Quantarray;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.212';



{ package quantarray_file;

	require TRL::Microarray::Microarray_File::Data_File;

	our @ISA = qw( data_file );

	# setter for { _spot_data }, { _data_fields } and { _header_info }
	sub sort_data {
		my $self = shift;
		my $aaData = shift;
		$self->set_header_info($aaData);
		$self->set_data_fields(shift @$aaData);
		my $aEnd_Line;
		while ($aEnd_Line = pop (@$aaData)){
			next unless ($$aEnd_Line[0]);	# deal with blank lines
			last if ($$aEnd_Line[0] =~ /^END DATA/);
		}
		$self->{ _spot_data } = $aaData;		# all the numbers
		$self->{ _spot_count } = scalar @$aaData;
	}
	# information about the scan
	sub set_header_info {
		my $self = shift;
		my $aaData = shift;
		my $hHeader_Info = { };
		my $header = 'end';
		while (my $aLine = shift @$aaData) {
			next unless $$aLine[0];
			if ($$aLine[0] =~ /^BEGIN DATA/) {
				last;			
			} elsif ($$aLine[0] =~ /^BEGIN/) {
				$header = $$aLine[0];
				next;
			} elsif ($$aLine[0] =~ /^END/) {
				$header = 'end';
				next;
			} elsif ($header eq 'end') {
				next;
			} elsif ($header =~ /IMAGE INFO/){
				next if ($$aLine[0] eq 'ImageID');	# header line
				
				my $ch = $$aLine[1];
				$hHeader_Info->{ 'num channels' }++;
				$hHeader_Info->{ "$ch Fluor" } = $$aLine[3];
				$hHeader_Info->{ "$ch Image" } = $$aLine[2];
				next unless ($ch eq 'CH1');
				$hHeader_Info->{ 'pixel size' } = $$aLine[6];
				$hHeader_Info->{ 'barcode' } = $$aLine[4];
			} else {
				if (@$aLine == 2){
					$hHeader_Info->{ $$aLine[0] } = $$aLine[1];
				} elsif (@$aLine > 2){
					for (my $i=1; $i<@$aLine; $i++){
						$hHeader_Info->{ 'CH'.$i.' '.$$aLine[0] } = $$aLine[$i];
					}
				}
			} 
		}
		$self->{ _header_info } = $hHeader_Info;
	}
	sub pixel_size {
		my $self = shift;
		$self->get_header_info('pixel size');
	}
	sub set_pixel_size {
		my $self = shift;
		my $hHeader_Info = $self->{ _header_info };		
		$hHeader_Info->{ 'pixel size' } = shift;
	}
	sub channel1_name {
		my $self = shift;
		$self->get_header_info('CH1 Fluor');
	}
	sub channel2_name {
		my $self = shift;
		$self->get_header_info('CH2 Fluor');
	}
	sub channel_name {
		my $self = shift;
		my $ch = shift;
		$self->get_header_info("CH$ch Fluor");
	}
	sub set_channel_name {
		my $self = shift;
		my $ch = shift;
		my $hHeader_Info = $self->{ _header_info };		
		$hHeader_Info->{ "CH$ch Fluor" } = shift;
	}
	sub channel_id {
		my $self = shift;
		my $ch = shift;
		"CH$ch";
	}
	sub num_channels {
		my $self = shift;
		$self->get_header_info('num channels');
	}
	sub slide_barcode {
		my $self = shift;
		if ($self->get_header_info('barcode')){
			return $self->get_header_info('barcode');
		} else {
			warn 	"TRL::Microarray::Microarray_File::Quantarray WARNING: \n".
					"Data file '".$self->file_name."'\n".
					"Could not find a barcode in the header information - guessing its the first part of the file name\n";
			#$self->guess_barcode;	# from data_file
		}
	}
	sub gal_file {
		my $self = shift;
		$self->get_header_info('GalFile');
	}
	sub analysis_software {
		'ScanArray Express v3';
	}
	sub scanner {
		my $self = shift;
		$self->get_header_info('Scanner');
	}
	sub user_comment {
		my $self = shift;
		$self->get_header_info('User comments');
	}
	sub channel1_image_file {
		my $self = shift;
		$self->get_header_info('CH1 Image');
	}
	sub channel2_image_file {
		my $self = shift;
		$self->get_header_info('CH2 Image');
	}
	sub channel_image_file {
		my $self = shift;
		my $ch = shift;
		$self->get_header_info("CH$ch Image");
	}
	sub channel1_pmt {
		my $self = shift;
		$self->get_header_info('CH1 PMT Voltages');
	}
	sub channel2_pmt {
		my $self = shift;
		$self->get_header_info('CH2 PMT Voltages');
	}
	sub channel_pmt {
		my $self = shift;
		my $ch = shift;
		$self->get_header_info("CH$ch PMT Voltages");
	}
	sub channel1_laser {
		my $self = shift;
		$self->get_header_info('CH1 Laser Powers');
	}
	sub channel2_laser {
		my $self = shift;
		$self->get_header_info('CH2 Laser Powers');
	}
	sub channel_laser {
		my $self = shift;
		my $ch = shift;
		$self->get_header_info("CH$ch Laser Powers");
	}
	sub array_columns {
		my $self = shift;
		$self->get_header_info('Array Columns');
	}
	sub array_rows {
		my $self = shift;
		$self->get_header_info('Array Rows');
	}
	sub spot_columns {
		my $self = shift;
		$self->get_header_info('Spot Columns');
	}
	sub spot_rows {
		my $self = shift;
		$self->get_header_info('Spot Rows');
	}
	### data file fields ###
	### NOTE: shifting in the array index, NOT the spot index ###	
	sub spot_index {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Index'));
	}
	sub block_row {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Array Row'));
	}
	sub block_col {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Array Column'));
	}
	sub spot_row {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Spot Row'));
	}
	sub spot_col {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Spot Column'));
	}
	sub x_pos {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('X'));
	}
	sub y_pos {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Y'));
	}
	sub spot_diameter {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Diameter'));
	}
	sub feature_id {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Name'));
	}
	sub synonym_id {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('ID'));
	}
	sub spot_pixels {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('F Pixels'));
	}
	sub bg_pixels {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('B Pixels'));
	}
	sub footprint {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Footprint'));
	}
	sub flag_id {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Flags'));
	}
	sub ch1_mean_f {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch1 Mean'));
	}
	sub ch1_median_f {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch1 Median'));
	}
	sub ch1_sd_f {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch1 SD'));
	}
	sub ch1_mean_b {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch1 B Mean'));
	}
	sub ch1_median_b {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch1 B Median'));
	}
	sub ch1_sd_b {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch1 B SD'));
	}
	sub ch1_b1sd {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch1 % > B + 1 SD'));
	}
	sub channel1_quality {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch1 % > B + 2 SD'));
	}
	sub channel1_sat {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch1 F % Sat.'));
	}
	sub ch2_mean_f {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch2 Mean'));
	}
	sub ch2_median_f {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch2 Median'));
	}
	sub ch2_sd_f {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch2 SD'));
	}
	sub ch2_mean_b {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch2 B Mean'));
	}
	sub ch2_median_b {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch2 B Median'));
	}
	sub ch2_sd_b {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch2 B SD'));
	}
	sub ch2_b1sd {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch2 % > B + 1 SD'));
	}
	sub channel2_quality {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch2 % > B + 2 SD'));
	}
	sub channel2_sat {
		my $self = shift;
		$self->return_data(shift,$self->get_column_id('Ch2 F % Sat.'));
	}

	###Êquantarray calculates SNR as (median signal/background SD) ###
	sub channel1_snr {
		my $self = shift;
		my $index = shift;
		my $median = $self->ch1_median_f($index);
		my $sd = $self->ch1_sd_b($index);
		if ($median && $sd) {
			return $median / $sd;
		} elsif ($median) {
			return $median;
		} else {
			return 0;
		}
	}
	sub channel2_snr {
		my $self = shift;
		my $index = shift;
		my $median = $self->ch2_median_f($index);
		my $sd = $self->ch2_sd_b($index);
		if ($median && $sd) {
			return $median / $sd;
		} elsif ($median) {
			return $median;
		} else {
			return 0;
		}
	}
	sub bad_flags {
		{ '1'=>'1', '2'=>'1', '4'=>'1' };
	}
}

{ package quantarray_image;

	require TRL::Microarray::Microarray_File;

	our @ISA = qw( microarray_image_file );
	
	sub set_header_data {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		KEY:while (my ($key,$value) = each %$hInfo){
			next unless ($value);
			my $value = $hInfo->{ $key };
			if (ref $value){
				next KEY;
			} elsif ($key eq 'ImageDescription'){
				my @aInfo = split(/#/,$value);
				for my $info (@aInfo){
					my @aItem = split(/=/,$info);
					if (@aItem == 2){
						$self->{ $aItem[0] } = $aItem[1];
					}
				}
			} else {
				$self->{ $key } = $value;
			}
		}		
	}
	sub protocol_name {
		my $self = shift;
		$self->{ ProtocolName };
	}
	sub protocol_description {
		my $self = shift;
		$self->{ ProtocolDesc };
	}
	sub protocol_id {
		my $self = shift;
		$self->{ ProtocolID };
	}
	sub image_user_name {
		my $self = shift;
		$self->{ Artist };
	}
	sub scan_speed {
		my $self = shift;
		if ($self->{ FullSpeed } == 0){
			return 50;
		} else {
			return 100;
		}
	}
	
	sub image_datetime {
		my $self = shift;
		my ($date,$time) = split(/\s/,$self->{ FileModifyDate });
		$date =~ s/:/-/g;
		return "$date $time";
	}
	sub image_scanner {
		my $self = shift;
		my $scanner = $self->{ Model };
		$scanner =~ s/\t/ /g;
		$scanner;
	}
	sub collection_software {
		my $self = shift;
		$self->{ Software };
	}
	sub slide_barcode {
		my $self = shift;
		if($self->image_lbarcode && $self->image_ubarcode){
			if ($self->image_lbarcode eq $self->image_ubarcode){
				return $self->image_ubarcode;
			} else {
				die "TRL::Microarray::Microarray_File::Quantarray ERROR: \n".
					"Image file '".$self->file_name."'\n".
					"Upper and lower barcodes are different\n";
			}
		} elsif ($self->image_lbarcode){
			return $self->image_lbarcode;
		} elsif ($self->image_ubarcode){
			return $self->image_ubarcode;
		} else {
			warn 	"TRL::Microarray::Microarray_File::Quantarray WARNING: \n".
					"Image file '".$self->file_name."'\n".
					"Could not find a barcode in the image header - guessing its the first part of the file name\n";
			#return $self->guess_slide_barcode;
		}
	}
	sub image_lbarcode {
		my $self = shift;
		$self->{ LBarcode };
	}
	sub image_ubarcode {
		my $self = shift;
		$self->{ UBarcode };
	}
	sub image_resolution {
		my $self = shift;
		$self->{ Resolution };
	}
	sub fluor_name {
		my $self = shift;
		$self->{ FluorName };
	}
	sub fluor_id {
		my $self = shift;
		$self->{ FluorID };
	}
	sub fluor_description {
		my $self = shift;
		$self->{ FluorDesc };
	}
	sub fluor_excitation {
		my $self = shift;
		$self->{ Excitation };
	}
	sub fluor_emission {
		my $self = shift;
		$self->{ Emission };
	}
	sub laser_id {
		my $self = shift;
		$self->{ Laser };
	}
	sub filter_id {
		my $self = shift;
		$self->{ Filter };
	}
	sub user_comment {
		my $self = shift;
		$self->{ UserComment };
	}
	sub pmt_gain {
		my $self = shift;
		$self->{ PMTGain };
	}
	sub laser_power {
		my $self = shift;
		$self->{ LaserPower };
	}
	sub set_new_barcode {
		my $self = shift;
		my $barcode = shift;
		my $new_file = shift;

		my $exifTool = $self->get_exiftool_object;
		my $value = $exifTool->GetValue('ImageDescription');					# the Quantarray header
		my $newValue = $value;
		
		if ($self->image_lbarcode || $self->image_ubarcode){
			if ($self->image_lbarcode){
				$self->{ LBarcode } = $barcode;
				$newValue =~ s/#LBarcode=.*#UBarcode/#LBarcode=$barcode#UBarcode/;	# change the lower barcode
			}
			if ($self->image_ubarcode){
				$self->{ UBarcode } = $barcode;
				$newValue =~ s/#UBarcode=.*#Resolution/#UBarcode=$barcode#Resolution/;	# change the upper barcode
			}
		} else {
				$self->{ LBarcode } = $barcode;
				$newValue =~ s/#LBarcode=.*#UBarcode/#LBarcode=$barcode#UBarcode/;	# change the lower barcode
				$self->{ UBarcode } = $barcode;
				$newValue =~ s/#UBarcode=.*#Resolution/#UBarcode=$barcode#Resolution/;	# change the upper barcode
		}
		
		$exifTool->SetNewValue('ImageDescription', $newValue);					# set the header with the new value
		my $success = $exifTool->WriteInfo($self->file_name, $new_file);		# write the new header to the destination file
		return $success;														# 1=write success, 2=write success no changes, 0=write error
	}
}

1;

__END__

=head1 NAME

TRL::Microarray::Microarray_File::Quantarray - A Perl module for managing Perkin Elmer 'Scanarray' microarray files

=head1 SYNOPSIS

	use TRL::Microarray::Microarray_File::Quantarray;

	my $data_file = quantarray_file->new("/file.csv");
	my $ch1_image = quantarray_image->new("/image1.tif");

=head1 DESCRIPTION

TRL::Microarray::Microarray_File::Quantarray is an object-oriented Perl module for managing microarray files created by Perkin Elmer's 'Scanarray' software. It inherits from TRL::Microarray::Microarray_File, and maps data fields in a Scanarray data file to those used by TRL::Microarray::Microarray_File::Data_File, as well as extracting header information from image files. 

=head1 METHODS

=head2 quantarray_file methods

In case you didn't guess - where a method exists for "channel1" in the following methods, there is an equivalent method for "channel2". 

=head3 General methods - typically retrieving information from the header

=over

=item pixel_size

Measured in micrometers. 

=item channel1_name

i.e. Cyanine 3, or Cyanine 5. This comes from Scanarray's fluorochrome list, and represents whatever fluor you chose in the scan set up.

=item channel1_image_file

The full path of the image file when saved by Scanarray.

=item gal_file

The full path of the GAL file, when/if imported by Scanarray during data extraction. 

=item user_comment

No idea where this comes from. But its there in the data file.

=item analysis_software

=item num_channels

=item slide_barcode

=item channel1_pmt, channel1_laser

=item array_columns, array_rows

Number of columns and rows of blocks on the array

=item spot_columns, spot_rows

Number of columns and rows of spots in each block

=back

=head3 Spot methods 

Pass the spot index to these methods to return information for a particular spot. 

=over

=item block_row,block_col,spot_row,spot_col,spot_index

There is no 'block number' field in Scanarray files, so all coordinates are at row/column level.

=item feature_id, synonym_id

The 'Name' and 'ID' columns respectively. 

=item x_pos, y_pos

Spot centre location in pixels, from the top-left of the image. 

=item footprint

You'd better look this one up... but its something like how far away the spot centre is, compared to where it was expected to be. 

=item flag_id

The flag associated with the spot. 

=item ch1_median_f, ch1_mean_f, ch1_sd_f

Median, mean and SD values for the fluorescence measurements of spot pixels.

=item ch1_median_b, ch1_mean_b, ch1_sd_b

Median, mean and SD values for the fluorescence measurements of background pixels.

=item ch1_b1sd, channel1_quality, channel1_sat

The percent of spot pixels 1 SD above background, percent of spot pixels 2 SD above background, and percent of spot pixels that are saturated.

=item channel1_snr

Scanarray calculates signal to noise ratio as the median signal/background SD.

=back

=head2 quantarray_image methods

=over

=item image_barcode

Returns the barcode, if there is only one, or if there is one at each end of the array and they are identical. Otherwise, if there are two barcodes that are different it will die with an error. 

=item image_lbarcode

Returns the lower barcode

=item image_ubarcode

Returns the upper barcode

=item protocol_name, protocol_id, protocol_description

These methods return details of the Scanarray protocol used to scan and extract array data

=item image_resolution

Pixel size in microns

=item fluor_name, fluor_id, fluor_colour_name, fluor_description, fluor_excitation, fluor_emission

These methods return details of the fluorochrome specified in the scan protocol and visualised in this image. Not necessarily the fluorochrome used in the experiment!

=item laser_id, filter_id

The Scanarray IDs of the filter and laser used in the scan

=item pmt_gain, laser_power

Percentage values specified in the scan protocol

=item user_comment

User comment can contain the slide barcode

=back

=head3 Setting a new barcode

You can change the value of a barcode in the header information. You can't overwrite the original file, but you can write these header changes to a new image file. This is achieved using the Image::ExifTool module. 

	my $success = $image->set_new_barcode('new barcode','/new_file.tif');

The returned values are; 1=write success, 2=write success no changes, 0=write error. If you need to change any other values, you can do by manipulating the embedded Image::ExifTool object.

	my $exiftool = $image->get_exiftool_object;

=head1 SEE ALSO

TRL::Microarray, TRL::Microarray::Microarray_File, TRL::Microarray::Microarray_File::Data_File

=head1 AUTHOR

Christopher Jones, Translational Research Laboratories, Institute for Women's Health, University College London.

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
