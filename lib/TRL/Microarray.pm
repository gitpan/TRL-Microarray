package TRL::Microarray;

use 5.006;
use strict;
use warnings;
use Exporter;
our @ISA = qw( Exporter );
our $VERSION = '0.23';

require TRL::Microarray::Microarray_File;
use TRL::Microarray::Feature;
use TRL::Microarray::Spot;
require TRL::Microarray::Microarray_File::Data_File;
require TRL::Microarray::Microarray_File::Quantarray;
require TRL::Microarray::Microarray_File::GenePix;
require TRL::Microarray::Microarray_File::BlueFuse;
use TRL::Microarray::Image;

{ package microarray;

	# Constructor
	sub new {
		my $class = shift;
		my $self = { };
		bless $self, $class;
		$self->barcode(shift);					# barcode first

		if (@_){								# data file passed
			my $data_file = shift;				# data file
			$self->data_file($data_file);		# then load the data_file object
		}
		return $self;
	}
	
	############################
	#  general getter setters  #
	############################
	
	sub barcode {
		my $self = shift;
		@_	?	$self->{ _barcode } = shift
			:	$self->{ _barcode };
	}
	sub data_file {	
		my $self = shift;
		if (@_) {
			my $data_file = shift;
			if ((ref $data_file) && ($data_file->isa('data_file')) ){	# if data_file object, load directly
				$self->{ _data_file } = $data_file;
			} else {							# otherwise, if passed a file name
				my $oData_File = data_file->new($data_file);	# create the data_file object - let it guess the file format
				$self->{ _data_file } = $oData_File;			# then load the data_file object
			}
		} else {
			$self->{ _data_file };
		}	
	}
	# how are missing samples described in the GAL file?
	sub blank_feature {
		my $self = shift;
		if (@_) {
			$self->{ _blank_feature } = shift;
		} else {
			if (defined $self->{ _blank_feature }) {
				$self->{ _blank_feature };
			} else {
				$self->default_blank_feature;
			}
		}
	}
	sub default_blank_feature {
		'n/a';
	}
	# is there an experimental prefix to feature id?
	# anything beginning with a 'y' will be classed as 'yes', all others 'no'
	sub prefix {
		my $self = shift;
		if (@_) {
			$self->{ _prefix } = shift;
		} else {
			if (defined $self->{ _prefix }) {
				$self->{ _prefix };
			} else {
				$self->default_prefix;
			}
		}
	}
	sub default_prefix {
		'no'
	}
	sub channel1_dye_name {
		my $self = shift;
		my $data_file = $self->data_file;
		$data_file->channel1_name;
	}
	sub channel2_dye_name {
		my $self = shift;
		my $data_file = $self->data_file;
		$data_file->channel2_name;
	}
	sub long_ch1_name {
		my $self = shift;
		'ch1 ('.$self->channel1_dye_name.')';
	}
	sub long_ch2_name {
		my $self = shift;
		'ch2 ('.$self->channel2_dye_name.')';
	}
	sub which_channel {
		my $self = shift;
		my $dye_name = shift;
		# assumes channels are different dyes!
		if ($self->channel1_dye_name eq $dye_name) {
			return 'ch1';
		} elsif ($self->channel2_dye_name eq $dye_name) {
			return 'ch2';
		} else {
			return undef;
		}
	}
	# setter for data_file parameters used in feature selection
	sub set_param {
		my $self = shift;
		my %hArgs = @_;
		while(my($arg,$val) = each %hArgs){
			if ($self->can($arg)){
				$self->$arg($val);
			} else {
				die "TRL::Microrray ERROR; No parameter '$arg' is defined\n";
			}
		}
	}
			
	##############################
	# Microarray feature methods #
	##############################
	
	# set features scrolls through the spot data
	# and fills a feature object with all corresponding spot objects
	sub set_features {
		my $self = shift;
		$self->{ _features } = { };
		my $blank_feature 	= $self->blank_feature;	# missing samples
		my $data_file 		= $self->data_file;
		$data_file->set_spot_objects;
		my $aSpots 			= $data_file->get_spots;
		SPOT: for (my $i=1; $i<@$aSpots; $i++) {
			my $oSpot = $$aSpots[$i];
			next SPOT unless $oSpot;
			next SPOT unless ($oSpot->feature_id);
			next SPOT if ($oSpot->feature_id =~ /$blank_feature/i);
			$self->add_spot_to_feature($oSpot);
		}
	}
	# uses the spot feature_id to determine the array feature_id
	sub add_spot_to_feature {
		my $self = shift;
		my $oSpot = shift;
		if (my $oFeature = $self->get_feature($oSpot->feature_id)) {	# i.e. feature already defined
			$oFeature->add_feature_spot($oSpot);
		} else {	# create a new feature containing this spot
			my $oFeature = array_feature->new($oSpot->feature_id);
			$oFeature->add_feature_spot($oSpot);
			$self->add_feature($oFeature);
		}
	}
	sub add_feature {
		my $self = shift;
		my $oFeature = shift;
		my $hFeatures = $self->get_all_features;
		$hFeatures->{ $oFeature->feature_id } = $oFeature;
	}
	sub get_feature {
		my $self = shift;
		my $feature_id = shift;
		my $hFeatures = $self->get_all_features;
		return unless (defined $hFeatures->{ $feature_id });
		$hFeatures->{ $feature_id };
	}
	# returns a hash of features; key=feature_id, value=feature object
	sub get_all_features {
		my $self = shift;
		unless (defined $self->{ _features }){
			$self->set_feature_data;
		}
		$self->{ _features };
	}
	# returns an arrayref of spot objects for a given feature_id
	sub get_feature_spots {
		my $self = shift;
		my $oFeature = $self->get_feature(shift);
		$oFeature->get_feature_spots;
	}
	# returns an array of all feature objects
	sub get_feature_objects {
		my $self = shift;
		my $hFeatures = $self->get_all_features;
		my @aValues = values %$hFeatures;
		return \@aValues;
	}
	# returns an array of all feature ids
	sub get_feature_ids {
		my $self = shift;
		my $hFeatures = $self->get_all_features;
		my @aKeys = keys %$hFeatures;
		return \@aKeys;
	}	
	sub set_feature_data {
		my $self = shift;
		unless (defined $self->{ _features }){
			$self->set_features;
		}
		my $aFeatures = $self->get_feature_objects;
		for my $oFeature (@$aFeatures) {
			$self->sort_feature_data($oFeature);
			#$self->set_genetic_data($oFeature);
		}
	}
	sub sort_feature_data {
		my $self = shift;
		my $oFeature = shift;

		my $aSpots = $oFeature->get_feature_spots;
		
		# setting these variables now saves making many calls to the same methods!
		my $hBad_Flags 	= $self->data_file->bad_flags;
		my $low_signal = $self->low_signal;
		my $high_signal = $self->high_signal;
		my $percen_sat = $self->percen_sat;
		my $min_snr = $self->min_snr;
		my $signal_quality = $self->signal_quality;
		my $min_diameter = $self->min_diameter;
		my $max_diameter = $self->max_diameter;
		my $max_pixels = $self->max_pixels;
		my $min_pixels = $self->min_pixels;

		SPOT: for my $oSpot (@$aSpots) {
		
			$oSpot->spot_status(0); 	# set spot to 'rejected' at start
			next SPOT if (defined $hBad_Flags->{ $oSpot->flag_id });

			unless ($self->should_ignore_signal_qa){
				######## SIGNAL QUALITY ASSESSMENTS ########
				if (($oSpot->channel1_signal < $low_signal) 		||
					($oSpot->channel1_signal > $high_signal)		||
					($oSpot->channel1_sat && ($oSpot->channel1_sat > $percen_sat))			||
					($oSpot->channel1_snr < $min_snr)				||
					($oSpot->channel1_quality < $signal_quality)	||
					($oSpot->channel2_signal < $low_signal) 		||
					($oSpot->channel2_signal > $high_signal) 		||
					($oSpot->channel2_sat && ($oSpot->channel2_sat > $percen_sat))			||
					($oSpot->channel2_snr < $min_snr)				||
					($oSpot->channel2_quality < $signal_quality) ){
					next SPOT;			
				} 
			}
			unless ($self->should_ignore_spot_qa){
				######## SPOT QUALITY ASSESSMENTS ########
				if (($oSpot->spot_diameter < $min_diameter) 		|| 
					($oSpot->spot_diameter > $max_diameter)){
					next SPOT;			
				} 
			}		
			# spot passes quality assessment

			$oSpot->spot_status(1);
			$oFeature->good_spot; 
			# for calculation of modal signal ratios
			$self->all_ch1($oSpot->channel1_signal);
			$self->all_ch2($oSpot->channel2_signal);
			# for calculation of feature signal ratios
			$oFeature->all_ch1($oSpot->channel1_signal);
			$oFeature->all_ch2($oSpot->channel2_signal);
			# for some plots
			$self->x_pos($oSpot->x_pos);
			$self->y_pos($oSpot->y_pos);
			unless ($oSpot->channel2_signal == 0){
				$self->all_ratios(($oSpot->channel1_signal)/($oSpot->channel2_signal));
				$oFeature->all_ratios(($oSpot->channel1_signal)/($oSpot->channel2_signal));
			}
		}
	}
#	some ideas for filtering using environment variables	
#	sub filter_or_not {
#		my $self = shift;
#		if (@_){
#			if (shift eq 'Y'){
#				$ENV{ FILTER } = 'Y';
#			} else {
#				$ENV{ FILTER } = 'N';
#			}
#		}
#	}
#	sub {
#		$ENV{ REJECT_UNIQUE }
#	}
#	sub filter_values {
#		$ENV{ FILTER_VALUES } = [500,0.5];
#	}
#	sub filter_on {
#		$ENV{ FILTER_ON } = [channel_signal,channel_quality];
#	}
	sub ignore_signal_qa {
		my $self = shift;
		$self->{ _ignore_signal_qa }++;
	}
	sub ignore_spot_qa {
		my $self = shift;
		$self->{ _ignore_spot_qa }++;
	}
	sub should_ignore_signal_qa {
		my $self = shift;
		$self->{ _ignore_signal_qa };
	}
	sub should_ignore_spot_qa {
		my $self = shift;
		$self->{ _ignore_spot_qa };
	}
	
	# the methods all_ch1/ch2/ratios create an array ref
	# containing all the relevant values from the array
	# these arrayrefs can be analysed for QC purposes
	# using Statistics::Descriptive
	sub all_ch1 {
		my $self = shift;
		unless (defined $self->{ _all_ch1 }){
			$self->{ _all_ch1 } = [];
		}
		if (@_){
			my $aCh1_Signals = $self->{ _all_ch1 };
			push (@$aCh1_Signals, shift);
		} else {
			$self->{ _all_ch1 };
		}
	}
	sub all_ch2 {
		my $self = shift;
		unless (defined $self->{ _all_ch2 }){
			$self->{ _all_ch2 } = [];
		}
		if (@_){
			my $aCh2_Signals = $self->{ _all_ch2 };
			push (@$aCh2_Signals, shift);
		} else {
			$self->{ _all_ch2 };
		}
	}
	sub x_pos {
		my $self = shift;
		unless (defined $self->{ _x_pos }){
			$self->{ _x_pos } = [];
		}
		if (@_){
			my $aX_Pos = $self->{ _x_pos };
			push (@$aX_Pos, shift);
		} else {
			$self->{ _x_pos };
		}
	}
	sub y_pos {
		my $self = shift;
		unless (defined $self->{ _y_pos }){
			$self->{ _y_pos } = [];
		}
		if (@_){
			my $aY_Pos = $self->{ _y_pos };
			push (@$aY_Pos, shift);
		} else {
			$self->{ _y_pos };
		}
	}
	sub all_ratios {
		my $self = shift;
		unless (defined $self->{ _all_ratios }){
			$self->{ _all_ratios } = [];
		}
		if (@_){
			my $aRatios = $self->{ _all_ratios };
			push (@$aRatios, shift);
		} else {
			$self->{ _all_ratios };
		}
	}
	# summary of why spots were rejected
	sub error_report {
		my $self = shift;
		if (defined $self->{ _error_report }) {
			$self->{ _error_report };
		} else {
			$self->{ _error_report } = { };
		}
	}

	#################################
	#  Getter setters for spot      #
	#  quality assessment criteria  #
	#################################

	# signal levels; set to linear range of the scanner
	sub low_signal {
		my $self = shift;
		if (@_) {
			$self->{ _low_signal } = shift;
		} else {
			if (defined $self->{ _low_signal }) {
				$self->{ _low_signal };
			} else {
				$self->default_low_signal;
			}
		}
	}
	sub default_low_signal {
		5000;
	}
	sub high_signal {
		my $self = shift;
		if (@_) {
			$self->{ _high_signal } = shift;
		} else {
			if (defined $self->{ _high_signal }) {
				$self->{ _high_signal };
			} else {
				$self->default_high_signal;
			}
		}
	}
	sub default_high_signal {
		60000;
	}
	# % of pixels that are saturated
	# provides check that signals are within the linear range
	# and also helps to flag 'dirty' spots
	sub percen_sat {
		my $self = shift;
		if (@_) {
			$self->{ _percen_sat } = shift;
		} else {
			if (defined $self->{ _percen_sat }) {
				$self->{ _percen_sat };
			} else {
				$self->default_percen_sat;
			}
		}
	}
	sub default_percen_sat {
		10;
	}
	# minimum acceptable spot signal:noise ratio
	sub min_snr {
		my $self = shift;
		if (@_) {
			$self->{ _snr } = shift;
		} else {
			if (defined $self->{ _snr }) {
				$self->{ _snr };
			} else {
				$self->default_min_snr;
			}
		}
	}	
	sub default_min_snr {
		10;
	}
	# subjective assessment of signal quality, using (% signal > B + 2SD)
	sub signal_quality {
		my $self = shift;
		if (@_) {
			$self->{ _signal_quality } = shift;
		} else {
			if (defined $self->{ _signal_quality }) {
				$self->{ _signal_quality };
			} else {
				$self->default_signal_quality;
			}
		}
	}
	sub default_signal_quality {
		95;
	}
	# spot size
	#�by combining stringent diameter checking with
	#�expected pixel number, we can check the 
	# 'circularity' of a spot
	sub min_diameter {
		my $self = shift;
		if (@_) {
			$self->{ _min_diameter } = shift;
		} else {
			if (defined $self->{ _min_diameter }) {
				$self->{ _min_diameter };
			} else {
				$self->default_min_diameter;
			}
		}
	}
	sub default_min_diameter {
		80;
	}
	sub max_diameter {
		my $self = shift;
		if (@_) {
			$self->{ _max_diameter } = shift;
		} else {
			if (defined $self->{ _max_diameter }) {
				$self->{ _max_diameter };
			} else {
				$self->default_max_diameter;
			}
		}
	}
	sub default_max_diameter {
		150;
	}
	sub target_diameter {
		my $self = shift;
		if (@_) {
			$self->{ _target_diameter } = shift;
		} else {
			if (defined $self->{ _target_diameter }) {
				$self->{ _target_diameter };
			} else {
				$self->default_target_diameter;
			}
		}
	}
	sub default_target_diameter {
		100;
	}
	sub max_diameter_deviation {
		my $self = shift;
		if (@_) {
			$self->{ _max_diameter_deviation } = shift;
		} else {
			if (defined $self->{ _max_diameter_deviation }) {
				$self->{ _max_diameter_deviation };
			} else {
				$self->default_max_diameter_deviation;
			}
		}
	}
	sub default_max_diameter_deviation {
		10;
	}
	sub min_pixels {
		my $self = shift;
		if (@_) {
			$self->{ _min_pixels } = shift;
		} else {
			unless (defined $self->{ _min_pixels }) {
				$self->{ _min_pixels } = $self->pixel_area($self->min_diameter);
			}
			$self->{ _min_pixels };
		}
	}
	sub max_pixels {
		my $self = shift;
		if (@_) {
			$self->{ _max_pixels } = shift;
		} else {
			unless (defined $self->{ _max_pixels }) {
				$self->{ _max_pixels } = $self->pixel_area($self->max_diameter);
			}
			$self->{ _max_pixels };			
		}
	}
	sub pixel_area {
		my $self = shift;
		my $micron_diameter = shift;	# spot diameter in microns
		my $data_file = $self->data_file;
		my $pixel_size = $data_file->pixel_size;	# each channel, in microns
		my $pixel_radius = ($micron_diameter/$pixel_size)/2;	# radius as number of pixels
		my $pixel_area = 3.14159 * ($pixel_radius * $pixel_radius);	# area as number of pixels
		return int($pixel_area + 0.49999);	# ensure correct rounding of a positive value
	}
	sub target_pixels {
		my $self = shift;
		if (@_) {
			$self->{ _target_pixels } = shift;
		} else {
			if (defined $self->{ _target_pixels }) {
				$self->{ _target_pixels };
			} else {
				$self->pixel_area($self->default_target_diameter);
			}
		}
	}
	sub normalisation {	# modal log2 ratio normalisation
		my $self = shift;
		if (@_){
			$self->{ _normalisation } = shift;
		} else {
			unless (defined $self->{ _normalisation }){
				return 'yes';
			}
			if ($self->{ _normalisation } =~ /^n/i){
				return undef;
			} else {
				return 'yes';
			}
		}
	}
	sub signal_normalisation {	# from scanner output
		my $self = shift;
		if (@_){
			$self->{ _signal_normalisation } = shift;
		} else {
			unless (defined $self->{ _signal_normalisation }){
				return 'yes';
			}
			if ($self->{ _signal_normalisation } =~ /^n/i){
				return undef;
			} else {
				return 'yes';
			}
		}
	}
	#�genetic_data_source defines whether we get the genetic data from file or database
	# currently, 'data_file' means from the results file (ie what was in the GAL file)
	# 'database' from array_pipeline_v4.chori_bac_clone_info
	# can expand to fetch it from separate file, and also to specify database table if different
	sub genetic_data_source {
		my $self = shift;
		if (@_) {
			$self->{ _genetic_data_source } = shift;
		} else {
			if (defined $self->{ _genetic_data_source }) {
				$self->{ _genetic_data_source };
			} else {
				$self->default_gendata_source;
			}
		}
	}
	sub default_gendata_source {
		'data_file';
	}
	# user defined headers for data output
	sub format_headers {
		my $self = shift;
		if (@_){
			my @aHeaders = @_;
			$self->{ _format_headers } = \@aHeaders;
		} else {
			if (defined $self->{ _format_headers }){
				$self->{ _format_headers };
			} else {
				$self->default_format_headers;
			}
		}
	}
	
	### image output ###
	sub set_image_data {
		my $self = shift;
		my $oImage = shift;
		$oImage->{ _ch1_values } = $self->all_ch1;
		$oImage->{ _ch2_values } = $self->all_ch2;
		$oImage->{ _x_coords } = $self->x_pos;
		$oImage->{ _y_coords } = $self->y_pos;
		$oImage->process_data;	# by-pass $oImage->set_data
	}	
	sub plot_ma {
		my $self = shift;
		my $oImage = ma_plot->new();
		$self->set_image_data($oImage);
		$oImage->make_plot;
	}
	sub plot_ri {
		my $self = shift;
		my $oImage = ri_plot->new();
		$self->set_image_data($oImage);
		$oImage->make_plot;
	}
	sub plot_intensity_scatter {
		my $self = shift;
		my $oImage = intensity_scatter->new();
		$self->set_image_data($oImage);
		$oImage->make_plot;
	}
	sub plot_log2_heatmap {
		my $self = shift;
		my $oImage = log2_heatmap->new();
		$self->set_image_data($oImage);
		$oImage->make_plot;
	}
	sub plot_intensity_heatmap {
		my $self = shift;
		my $oImage = intensity_heatmap->new();
		$self->set_image_data($oImage);
		$oImage->make_plot;
	}

}

1;

__END__

=head1 NAME

TRL::Microarray - A Perl module for creating and manipulating microarray objects

=head1 SYNOPSIS

	use TRL::Microarray;

	my $oArray = microarray->new($barcode,$data_file);
	$oArray->set_feature_data;

=head1 DESCRIPTION

TRL::Microarray is an object-oriented Perl module for creating microarray data objects, and analysing the results. The module currently supports import of Axon 'GenePix', Perkin-Elmer 'Scanarray' and BlueGnome 'BlueFuse' data file formats, and the output of several data plots such as scatter, heatmap and MA plots. 

=head2 How it works

The Microarray object contains several levels of microarray associated data, organised in a (fairly) intuitive way. First, there's the data that you have obtained from a microarray scanner, in the form of a data file. This is imported into Microrray as a Data_File object. Support for different data file formats is built into the Data_File class, and creating new classes for your favourite scanner/software output is relatively simple. Data extracted from the microarray spots are then imported into individual array_spot objects. Next, replicate spots are collated into array_feature objects. Most of the quality control functions operating on parameters such as signal intensity and spot size, are built into this final process, so that an array_feature object only contains data from spots that have passed the QC assessments. Finally, sub-classes of Microarray (such as cgh_array) provide methods for adding genetic data to each feature, and also methods for basic data processing (such as returning signal ratios, or ratio normalisation). 

=head1 METHODS

=head2 Creating microarray objects

The microarray object is created by providing a barcode (or name) and a data file. It is assumed the data file contains minimal information about the feature identities (i.e. name or id). In the case of a CGH-microarray, that means the BAC clone name/synonym at each spot. For (currently unsupported) cDNA or oligo arrays, that would mean a gene name, cDNA accession, or oligo name. Most of the functions between initialising the objects and returning formatted data can be accessed, and default settings can be changed (see below).

=head2 Data File

The data file can be passed to Microarray either as a file name, filehandle object, or data_file object. If a filehandle is passed, the filename also needs to be set. 

	$oArray = microarray->new($barcode,'my_file');  	# will try to guess the file format
	
	or
	
	$oData_File = quantarray_file->new('my_file');  	# create the data file...
	$oData_File = quantarray_file->new('my_file',$Fh);  # can pass a filename and filehandle to the data file
	$oArray = microarray->new($barcode,$oData_File);  	# ...then load into microarray

=head2 Feature Identification

=over

=item blank_feature

Defines how 'empty' spots are described in the data file. Default 'n/a'

=item prefix

Set to 'y' if the feature id is prefixed in some way (for instance, we use prefixes to distinguish different methods used to prepare the same sample for microarray spotting). Default 'n'

=back

=head2 Changing Default Settings

There are many parameters that are used in the process of defining features, and for their quality control. Below is an overview of the methods used. As well as being able to set these parameters individually, you can also set a number in one call using the set_param() method

	$array->set_param(min_diameter=>100,min_snr=>10);

=head3 Spot Quality Control

There are various (mostly self-explanatory) methods for setting spot quality control measurements, listed below

=over

=item low_signal, high_signal

Defaults = 5000, 60000

=item min_diameter, max_diameter

Default = 80, 150

=item min_pixels

Default = 80

=item signal_quality

Varies depending on the data file format used; for the ScanArray format, this refers to the percentage of spot pixels that are more than 2 standard deviations above the background (default = 95); for BlueFuse this corresponds to the spot confidence value. 

=item percen_sat

The method percen_sat() refers to the percentage of spot pixels that have a saturated signal. Default = 10. Not relevant to BlueFuse format.

=back

=head3 Feature Analysis

=over

=item normalisation

Set to either 'y' or 'n', to include ratio normalisation. Note: this is only base-level normalisation, not signal normalisation. For CGH-microarrays, this is a subtraction of the modal log2 ratio. Default = 'y'

=back

=head2 Access to Spot Data

All of the microarray data can be independently accessed in one of two ways. First, data can be obtained directly from the data file object, and in fact you could use this module just to simplify the data input process for your own applications and not use any of the other functions of Microarray. Individual spot objects can be returned by referring to their spot index (which is usually also the order they appear in the data file) or all spot objects can be returned as a list. See TRL::Microarray::Spot and TRL::Microarray::Feature for more information.

	my $spot = $oData_File->get_spots(1);
	my $aAll_Spots = $oData_File->get_spots;

=head3 Data file methods

=over

=item file_name

Depending how you used Data_File, will be the name or the full path you provided

=item get_header_info

For example in the ScanArray format, the data header contains information about the scan, such as laser power, PMT, etc

=back

=head2 Access to Feature Data

Alternatively you can access the feature data, which collates replicate spot data. Either, individual feature objects can be returned, and array_feature methods applied to them, or all feature objects/ids can be returned as a list. 

	$oFeature = $oArray->get_feature('feature1');  # returns a single feature object
	$aFeature_Objects = $oArray->get_feature_objects;  # returns a list of feature objects
	$aFeature_Names = $oArray->get_feature_ids;  # returns a list of feature ids
	$hFeatures = $oArray->get_all_features;  # returns a hash of features; key=feature_id, value=feature object

=head1 FUTURE DEVELOPMENT

This module is under continued development for our laboratory's microarray facility. If you would like to contribute to the development of Microarray, whether to add more advanced features of data analysis, or simply to add support for other microarray platforms/scanners, please contact the author. 

=head1 SEE ALSO

TRL::Microarray::Microarray_File, TRL::Microarray::Feature, TRL::Microarray::Spot

=head1 AUTHOR

Christopher Jones, Translational Research Laboratories, Institute for Women's Health, University College London.

c.jones@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Christopher Jones, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
