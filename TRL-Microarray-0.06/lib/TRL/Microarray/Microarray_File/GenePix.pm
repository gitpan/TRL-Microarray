package TRL::Microarray::Microarray_File::GenePix;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.02';


{ package genepix_file;

	require TRL::Microarray::Microarray_File::Data_File;

	our @ISA = qw( data_file );

	# setter for { _spot_data }, { _data_fields } and { _header_info }
	sub sort_data {
		my $self = shift;
		my $aaData = shift;
		my $aFile_Format = shift @$aaData;
		my $aRow_Cols = shift @$aaData;
		my $header_rows = $$aRow_Cols[0];
		my $col_num = $$aRow_Cols[1];
		$self->set_header_info($aaData,$header_rows);
		$self->set_data_fields(shift @$aaData);
		$self->set_spot_objects($aaData);	# all the numbers
	}
	# information about the scan
	sub set_header_info {
		my $self = shift;
		my $aaData = shift;
		my $header_rows = shift;
		my $hHeader_Info = { };
		for (my $i=1; $i<=$header_rows; $i++) {
			my $aLine = shift @$aaData;
			my ($key,$value) = split(/=/,$$aLine[0]);
			if ($value =~ /\t/){
				my @aValues = split(/\t/,$value);
				$hHeader_Info->{ "CH1 $key" } = $aValues[0];
				$hHeader_Info->{ "CH2 $key" } = $aValues[1];
			} else {
				$hHeader_Info->{ $key } = $value;
			}
		}
		$self->{ _header_info } = $hHeader_Info;
	}
	sub pixel_size {
		my $self = shift;
		$self->get_header_info('PixelSize');
	}
	sub num_channels {
		2
	}
	sub channel1_name {
		'Cy5'
	}
	sub channel2_name {
		'Cy3'
	}
	sub channel_id {
		my $self = shift;
		my $ch = shift;
		"CH$ch";
	}
	sub channel_name {
		my $self = shift;
		my $ch = shift;
		my $method = "channel".$ch."_name";
		$self->$method;
	}	
	sub slide_barcode {
		my $self = shift;
		$self->get_header_info('Barcode');
	}
	sub gal_file {
		my $self = shift;
		$self->get_header_info('GalFile');
	}
	sub analysis_software {
		my $self = shift;
		$self->get_header_info('Creator');
	}
	sub scanner {
		my $self = shift;
		$self->get_header_info('Scanner');
	}
	sub user_comment {
		my $self = shift;
		$self->get_header_info('Comment');
	}
	sub channel1_image_file {
		my $self = shift;
		$self->get_header_info('CH1 FileName');
	}
	sub channel2_image_file {
		my $self = shift;
		$self->get_header_info('CH2 FileName');
	}
	sub channel_image_file {
		my $self = shift;
		my $ch = shift;
		$self->get_header_info("CH$ch FileName");
	}
	sub channel1_pmt {
		my $self = shift;
		$self->get_header_info('CH1 PMTVolts');
	}
	sub channel2_pmt {
		my $self = shift;
		$self->get_header_info('CH2 PMTVolts');
	}
	sub channel_pmt {
		my $self = shift;
		my $ch = shift;
		$self->get_header_info("CH$ch PMTVolts");
	}
	sub channel1_laser {
		my $self = shift;
		$self->get_header_info('CH1 LaserPower');
	}
	sub channel2_laser {
		my $self = shift;
		$self->get_header_info('CH2 LaserPower');
	}
	sub channel_laser {
		my $self = shift;
		my $ch = shift;
		$self->get_header_info("CH$ch LaserPower");
	}
	# sets the spot object data
	sub set_spot_objects {
		my $self = shift;
		my $aaData = shift;
		my $aData_Fields = $self->data_file_fields;
		my $index = 0;
		while (my $aData_Row = shift @$aaData){	
			last unless ($$aData_Row[0]);
			$index++;
			my $oSpot = array_spot->new();						# new spot object
			for my $field (@$aData_Fields){						# each spot field name
				if ($field eq 'spot_index'){
					$oSpot->spot_index($index);
				} else {
					$oSpot->$field($self->$field($aData_Row));		#Êfill the spot object with the spot_row data
				}
			}
			# add spot object to data_file
			$self->add_spot($oSpot);
		}
	}	
	sub feature_id {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('Name') ];
	}
	sub synonym_id {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('ID') ];
	}
	sub ch1_mean_f {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('F635 Mean') ];
	}
	sub ch2_mean_f {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('F532 Mean') ];
	}
	sub ch1_mean_b {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('B635 Mean') ];
	}
	sub ch2_mean_b {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('B532 Mean') ];
	}
	sub ch1_median_b {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('B635 Median') ];
	}
	sub ch2_median_b {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('B532 Median') ];
	}
	sub ch1_b1_sd {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('% > B635+1SD') ];
	}
	sub ch2_b1_sd {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('% > B532+1SD') ];
	}
	sub block_row {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('Block') ];
	}
	sub block_col {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('Block') ];
	}
	sub spot_row {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('Row') ];
	}
	sub spot_col {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('Column') ];
	}
	sub channel1_signal {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('F635 Mean - B635') ];
	}
	sub channel2_signal {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('F532 Mean - B532') ];
	}
	sub channel_signal {
		my $self = shift;
		my $aData = shift;
		my $ch = shift;
		my $method = "channel".$ch."_signal";
		$self->$method($aData);
	}
	sub channel1_snr {
		my $self = shift;
		my $aData = shift;
		my $median = $self->ch1_median_f($aData);
		my $sd = $self->ch1_sd_b($aData);
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
		my $aData = shift;
		my $median = $self->ch2_median_f($aData);
		my $sd = $self->ch2_sd_b($aData);
		if ($median && $sd) {
			return $median / $sd;
		} elsif ($median) {
			return $median;
		} else {
			return 0;
		}
	}
	sub channel_snr {
		my $self = shift;
		my $aData = shift;
		my $ch = shift;
		my $method = "channel".$ch."_snr";
		$self->$method($aData);
	}
	sub ch1_sd_b {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('B635 SD') ];
	}
	sub ch2_sd_b {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('B532 SD') ];
	}
	sub ch1_sd_f {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('F635 SD') ];
	}
	sub ch2_sd_f {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('F532 SD') ];
	}
	sub ch1_median_f {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('F635 Median') ];
	}
	sub ch2_median_f {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('F532 Median') ];
	}
	sub channel1_quality {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('% > B635+2SD') ];
	}
	sub channel2_quality {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('% > B532+2SD') ];
	}
	sub channel_quality {
		my $self = shift;
		my $aData = shift;
		my $ch = shift;
		my $method = "channel".$ch."_quality";
		$self->$method($aData);
	}
	sub channel1_sat {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('F635 % Sat.') ];
	}
	sub channel2_sat {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('F532 % Sat.') ];
	}
	sub channel_sat {
		my $self = shift;
		my $aData = shift;
		my $ch = shift;
		my $method = "channel".$ch."_sat";
		$self->$method($aData);
	}
	sub spot_diameter {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('Dia.') ];
	}
	sub spot_pixels {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('F Pixels') ];
	}
	sub flag_id {
		my $self = shift;
		my $aData = shift;
		$$aData[ $self->get_column_id('Flags') ];
	}
	sub bad_flags {
		{ '-50'=>'1', '-75'=>'1' }
	}
}

{ package genepix_image;

	require TRL::Microarray::Microarray_File;

	our @ISA = qw( microarray_image_file );
	
	sub set_header_data {
		my $self = shift;
		my $hInfo = $self->get_header_info;
		
		# add split and set data here

	}
}

1;

__END__

=head1 NAME

TRL::Microarray::Microarray_File::GenePix - A Perl module for managing microarray Axon GenePix data files

=head1 SYNOPSIS

	use TRL::Microarray::Microarray_File::GenePix;

	my $data_file = genepix_file->new("/file.csv");
	my $image_file = genepix_image->new("/image.tif");

=head1 DESCRIPTION

TRL::Microarray::Microarray_File::GenePix is an object-oriented Perl module for managing microarray data files created by Axon's GenePix software. It inherits from TRL::Microarray::Microarray_File, and maps data fields in the GenePix file to those used by TRL::Microarray::Microarray_File::Data_File. This module does not yet parse GenePix image header info, although at some point it is hoped this feature will be implemented.

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
