package TRL::Microarray::Image;

use 5.006;
use strict;
use warnings;

use GD::Image;
use TRL::Microarray::Microarray_File;
use TRL::Microarray::Microarray_File::GenePix;
use TRL::Microarray::Microarray_File::Agilent;
use TRL::Microarray::Microarray_File::Quantarray;

{ package plot;
  
  sub new {
    my $class = shift;
    my $self  = { };
    if (@_){
			$self->{ _data_object } = shift;
			bless $self, $class;
			$self->set_data;
		} else {
			  bless $self, $class;
			}
    return $self;
  }
  sub set_data {
    my $self = shift;
    my $oData;
    if (@_) {
      $oData = shift;
      $self->{ _data_object } = $oData;
    } elsif ($self->data_object) {
        $oData = $self->data_object;
      } else {
          die "TRL::Microarray::Image ERROR: No data object provided\n";
        }
    $self->sort_data;
    ## polymorphic method to process data such as MA RI log2 etc
    $self->process_data;
  }
  ## from data object the background adjusted intensity of ch1 and ch2 and x,y coordinates 
  ## are set in the plot image object
  sub sort_data {
    my $self   = shift;
    my $oData  = $self->data_object;
    my $spot_count = $oData->spot_count;
    my $aCh1   = [];
    my $aCh2   = [];
    my $aXcoords = [];
    my $aYcoords = [];
    for (my $i=0; $i<$spot_count; $i++){
      my $ch1 = $oData->channel1_signal($i);
      my $ch2 = $oData->channel2_signal($i);
      my $x_pos = $oData->x_pos($i);
      my $y_pos = $oData->y_pos($i);
      next if (($ch1 <= 0)||($ch2<=0));
      push(@$aCh1, $ch1);
      push(@$aCh2, $ch2);
      push(@$aXcoords, $x_pos);
      push(@$aYcoords, $y_pos);
    }
    $self->{ _ch1_values } = $aCh1;
    $self->{ _ch2_values } = $aCh2;
    $self->{ _x_coords }   = $aXcoords;
    $self->{ _y_coords }   = $aYcoords;
  }
  sub process_data {
    my $self = shift;
    my $aCh1 = $self->ch1_values;
    my $aCh2 = $self->ch2_values;
    ## if a process_data method is not set in plot class, simply use the raw intensity data
    $self->{ _x_values } = $aCh1;
    $self->{ _y_values } = $aCh2;
  }
  ## create a GD image and draw on it the desired plot
  sub make_plot {
    my $self  = shift;
    my $scale;
    if (@_) {
      $scale = shift;
    } else {
        $scale = 100;
      }
    $self->{ _scale } = $scale;
    ## Get the x and y coordiantes of the plot, dynamicaly set by the size of the dataset
    my ($x, $y) = $self->plot_dimensions;
    ## normalise the plot data according to the plot dimentions
    $self->plot_values;
    my $plot = GD::Image->new($x,$y);	
    
    $self->plot_outline($plot);
    $self->plot_spots($plot);
    $self->{ _image } = $plot->png;
    return($plot->png);
  }
  sub plot_dimensions {
    my $self = shift;
    my $scale = $self->scale;
    my $aY   = $self->y_values;
    my $aX   = $self->x_values;
    my ($y_min,$y_max,$y_range) = $self->data_range($aY);
    my ($x_min,$x_max,$x_range) = $self->data_range($aX);
    my $x = ($x_range * $scale);
    my $y = ($y_range * $scale);
    my $x_margin = 100;
    my $y_margin = 100;
    $self->{ _x_length } = $x;
    $self->{ _y_length } = $y;
    $self->{ _x_margin } = $x_margin;
    $self->{ _y_margin } = $y_margin;
    $self->{ _middle } = ($y + $y_margin)/2 ;
    return(($x + $x_margin), ($y + $y_margin));
  }
  sub plot_values {
    my $self = shift;
    my $aX = $self->x_values;
    my $aY = $self->y_values;
    ## if a plot_values method is not set in plot class, simply plot the raw data
    $self->{ _plotx_values } = $aX;
    $self->{ _ploty_values } = $aY;
  }
  sub set_plot_background {
    my $self = shift;
    my $image = shift;
    ## first allocated colour is set to background
    my $grey = $image->colorAllocate(180,180,180);
  }
  #sub set_plot_axis {
  #
  #}
  #sub set_plot_labels {
  #
  #}
  #sub set_plot_title {
  #
  #}
  # plot the outline of the diagram, ready for spots to be added
  sub plot_outline {
	  my $self = shift;
    my $image = shift;
    my $scale = $self->scale;
    $self->set_plot_background($image);
    my $aY   = $self->ploty_values;
    my $aX   = $self->plotx_values;
    my ($x_min,$x_max,$x_range) = $self->data_range($aX);
    my ($y_min,$y_max,$y_range) = $self->data_range($aY);
    my $middle = $self->middle;
	  my $x_length = $self->x_length;
	  my $y_length = $self->y_length;
	  my $x_margin = $self->x_margin;
    my $y_margin = $self->y_margin;
	  # get colours from the GD colour table 
	  my $black = $image->colorExact(0,0,0);
	  ## x axis
	  $image->filledRectangle(50,$y_length+50,$x_length+50,$y_length+50,$black);
	  ## y axis
	  $image->filledRectangle(50,50,50,$y_length+50,$black);
	  ## x axis label
	  my $max_label = int($x_max);
	  my $min_label = int($x_min);
	  $image->string($image->gdGiantFont,($x_length+50)/2,$y_length+80,"(0.5)*Log2(R*G)",$black);
	  $image->string($image->gdGiantFont,(($x_min-$x_min)*$scale)+50,$y_length+70,"$min_label",$black);
	  $image->string($image->gdGiantFont,(($x_max-$x_min)*$scale)+50,$y_length+70,"$max_label",$black);
    ## y axis label
	  $image->stringUp($image->gdGiantFont,10,$middle,"Log2(R/G)",$black);
	  $image->stringUp($image->gdGiantFont,30,$middle - 25,"0",$black);
  }
  ## given a GD image object and X and Y data arrays this method will plot on the 
  ## image each X,Y data point in black
  sub plot_spots {
	  my $self = shift;
    my $plot = shift;
	  my $aX   = $self->plotx_values;
    my $aY   = $self->ploty_values;
	  my $black = $plot->colorExact(0,0,0);
	  for (my $i=0; $i<@$aX; $i++){
		  my $x = $aX->[$i];
		  my $y = $aY->[$i];
      next unless ($x && $y);
			$plot->filledEllipse($x,$y,3,3,$black);
			#$plot->setPixel($x,$y,$black);
	  }
  }
  ## finds the minimum, maximum and range of an array of data 
  sub data_range {
    my $self = shift;
    my $aData = shift;
    use Statistics::Descriptive;
    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@$aData);
    my $min = $stat->min();
    my $max = $stat->max();
    my $range = $stat->sample_range();
    return($min,$max,$range);
  }
  ## set graduated colours in the GD colour table, for use in the plot
  ## from red-yellow-green 
  sub make_colour_grads {
	  my $self  = shift;
    my $image = shift;
    my $count = 0;
	  for (my $i = 0; $i<=255; $i+=5){ 	
      $image->colorAllocate($i,255,0);
		  $image->colorAllocate(255,$i,0);
	  }	
    $image->colorAllocate(0,0,0);		
  }
  sub print_image {
    my $self = shift;
    my $image = $self->image;
    if (@_) {
      $self->{ _print_location} = shift;
      $self->{ _image_name} = shift;
    }
    my $name  = $self->get_image_name;  
    my $print_location = $self->get_print_location;
    open FH, $print_location.$name.".png";
    binmode(FH);
    print FH $image;
    close(FH);
  }
  sub image {
    my $self = shift;
    $self->{ _image };
  }
  sub get_image_name {
    my $self = shift;
    unless (defined $self->{ _image_name }){
			$self->set_image_name;
		}
		$self->{ _image_name };
  }
  sub set_image_name {
    my $self = shift;
    ## need to concat plot type and data source(file name/db id)
    my $image_name = 'image';
    $self->{ _image_name } = $image_name;
  }
  sub get_print_location {
    my $self = shift;
    unless (defined $self->{ _print_location }){
			$self->set_print_location;
		}
		$self->{ _print_location };
  }
  sub set_print_location {
    my $self = shift;
    my $print_location = ">C:/Documents and Settings/James_Morris/Desktop/";
    $self->{ _print_location } = $print_location;
  }
  sub file_path {
    my $self = shift;
    $self->{ _file_path };
  }
  sub microarray_file {
    my $self = shift;
    $self->{ _microarray_file };
  }
  sub ch1_values {
    my $self = shift;
    $self->{ _ch1_values };
  }
  sub ch2_values {
    my $self = shift;
    $self->{ _ch2_values };
  }
  sub middle {
    my $self = shift;
    $self->{ _middle };
  }
  sub scale {
    my $self = shift;
    $self->{ _scale };
  }
  sub x_length {
    my $self = shift;
    $self->{ _x_length };
  }
  sub y_length {
    my $self = shift;
    $self->{ _y_length };
  }
  sub x_margin {
    my $self = shift;
    $self->{ _x_margin };
  }
  sub y_margin {
    my $self = shift;
    $self->{ _y_margin };
  }
  sub x_values {
    my $self = shift;
    $self->{ _x_values };
  }
  sub feature_names {
    my $self = shift;
    $self->{ _feature_names };
  }
  sub y_values {
    my $self = shift;
    $self->{ _y_values };
  }
  sub plotx_values {
    my $self = shift;
    $self->{ _plotx_values };
  }
  sub ploty_values {
    my $self = shift;
    $self->{ _ploty_values };
  }
  sub ratio_values {
    my $self = shift;
    $self->{ _ratio_values };
  }
  sub x_coords {
    my $self = shift;
    $self->{ _x_coords };
  }
  sub y_coords {
    my $self = shift;
    $self->{ _y_coords };
  }
  sub data_object {
    my $self = shift;
    $self->{ _data_object };
  }
  sub data {
    my $self = shift;
    $self->{ _data };
  }
}
{ package ma_plot;
  
  our @ISA = qw( plot );
  
  sub process_data {
    my $self = shift;
    my $aCh1 = $self->ch1_values;
    my $aCh2 = $self->ch2_values;
    my $aMvalues = [];
    my $aAvalues = [];
    for (my $i=0; $i<@$aCh1; $i++){
      my $ch1 = $aCh1->[$i];
		  my $ch2 = $aCh2->[$i];
		  next unless ($ch1 && $ch2);
		  my $m = $self->calc_m($ch1, $ch2);
      my $a = $self->calc_a($ch1, $ch2);
      next unless ($m && $a);
      push(@$aMvalues, $m);
      push(@$aAvalues, $a);  
    }
    $self->{ _y_values } = $aMvalues;
    $self->{ _x_values } = $aAvalues;
  }
  sub plot_values {
    my $self = shift;
    my $aX = $self->x_values;
    my $aY = $self->y_values;
    my $scale  = $self->scale;
    my $middle = $self->middle;
    my ($y_min,$y_max,$y_range) = $self->data_range($aY);
    my ($x_min,$x_max,$x_range) = $self->data_range($aX);
    my $aXadjusted = [];
    my $aYadjusted = [];
    for (my $i=0; $i<@$aX; $i++){
      my $x = $aX->[$i];
		  my $y = $aY->[$i];
		  next unless ($x && $y);
      $x = (($x - $x_min) * $scale) + 50;
      $y = ($middle - ($y * $scale));
      push(@$aXadjusted, $x);
      push(@$aYadjusted, $y);  
    }
    $self->{ _plotx_values } = $aXadjusted;
    $self->{ _ploty_values } = $aYadjusted;
  }
  sub calc_m {
    my $self = shift;
    my $ch1  = shift;
    my $ch2  = shift;
    if (($ch1 == 0 )||($ch2 == 0)){
      return();  
    }
    return(log($ch1/$ch2)/log(2));
  }
  sub calc_a {
    my $self = shift;
    my $ch1  = shift;
    my $ch2  = shift;
    if (($ch1 == 0 )||($ch2 == 0)){
      return();  
    }
    return(log(0.5*($ch1*$ch2))/log(2));
  }
}
{ package ri_plot;

  our @ISA = qw( ma_plot );
  
  sub process_data {
    my $self = shift;
    my $aCh1 = $self->ch1_values;
    my $aCh2 = $self->ch2_values;
    my $aRvalues = [];
    my $aIvalues = [];
    for (my $i=0; $i<@$aCh1; $i++){
      my $ch1 = $aCh1->[$i];
		  my $ch2 = $aCh2->[$i];
      next unless ($ch1 && $ch2);
      my $r_val = $self->calc_r($ch1, $ch2);
      my $i_val = $self->calc_i($ch1, $ch2);  
      next unless ($r_val && $i_val);  
      push(@$aRvalues, $r_val);
      push(@$aIvalues, $i_val);
    }
    $self->{ _y_values } = $aRvalues;
    $self->{ _x_values } = $aIvalues;
  }
  sub calc_r {
    my $self = shift;
    my $ch1  = shift;
    my $ch2  = shift;
    if (($ch1 == 0 )||($ch2 == 0)){
      return();  
    }
    return(log($ch1/$ch2)/log(2));
  }
  sub calc_i {
    my $self = shift;
    my $ch1  = shift;
    my $ch2  = shift;
    if (($ch1 == 0 )||($ch2 == 0)){
      return();  
    }
    return(log($ch1*$ch2)/log(2));
  }
  # plot the outline of the diagram, ready for spots to be added
  sub plot_outline {
	  my $self = shift;
    my $image = shift;
    my $scale = $self->scale;
	  ## first allocated colour is set to background
    my $grey = $image->colorAllocate(180,180,180);
    my $aM   = $self->ploty_values;
    my $aA   = $self->plotx_values;
    my ($m_min,$m_max,$m_range) = $self->data_range($aM);
    my ($a_min,$a_max,$a_range) = $self->data_range($aA);
    my $middle = $self->middle;
	  my $x_length = $self->x_length;
	  my $y_length = $self->y_length;
	  my $x_margin = $self->x_margin;
    my $y_margin = $self->y_margin;
	  # get colours from the GD colour table 
	  my $black = $image->colorExact(0,0,0);
	  ## x axis
	  $image->filledRectangle(50,$y_length+50,$x_length+50,$y_length+50,$black);
	  ## y axis
	  $image->filledRectangle(50,50,50,$y_length+50,$black);
	  ## x axis label
	  my $max_label = int($a_max);
	  my $min_label = int($a_min);
	  $image->string($image->gdGiantFont,($x_length+50)/2,$y_length+80,"Log2(R*G)",$black);
	  $image->string($image->gdGiantFont,(($a_min-$a_min)*$scale)+50,$y_length+70,"$min_label",$black);
	  $image->string($image->gdGiantFont,(($a_max-$a_min)*$scale)+50,$y_length+70,"$max_label",$black);
    ## y axis label
	  $image->stringUp($image->gdGiantFont,10,$middle,"Log2(R/G)",$black);
	  $image->stringUp($image->gdGiantFont,30,$middle - 25,"0",$black);
  }
}
{ package intensity_scatter;

  our @ISA = qw( plot );
  
  sub plot_dimensions {
    my $self = shift;
    my $scale = $self->scale;
    my $aX    = $self->x_values;
    my $aY    = $self->y_values;
    my ($x_min,$x_max,$x_range) = $self->data_range($aX);
    my ($y_min,$y_max,$y_range) = $self->data_range($aY);
    my $x = ($x_max / $scale);
    my $y = ($y_max / $scale);
    my $x_margin = 100;
    my $y_margin = 100;
    $self->{ _x_length } = $x;
    $self->{ _y_length } = $y;
    $self->{ _x_margin } = $x_margin;
    $self->{ _y_margin } = $y_margin;
    $self->{ _middle } = ($y + $y_margin)/2 ;
    return(($x + $x_margin), ($y + $y_margin));
  }
  sub plot_values {
    my $self = shift;
    my $aX = $self->x_values;
    my $aY = $self->y_values;
    my $scale  = $self->scale;
    my $x_length = $self->x_length;
	  my $y_length = $self->y_length;
    my $x_margin = $self->x_margin;
    my $y_margin = $self->y_margin;
    my ($y_min,$y_max,$y_range) = $self->data_range($aY);
    my ($x_min,$x_max,$x_range) = $self->data_range($aX);
    my $aXadjusted = [];
    my $aYadjusted = [];
    for (my $i=0; $i<@$aX; $i++){
      my $x = $aX->[$i];
		  my $y = $aY->[$i];
		  next unless ($x && $y);
      $x = (($x/$scale))+50;
		  $y = ($y_length-($y/$scale))+50;
      push(@$aXadjusted, $x);
      push(@$aYadjusted, $y);  
    }
    $self->{ _plotx_values } = $aXadjusted;
    $self->{ _ploty_values } = $aYadjusted;
  }
  # plot the outline of the diagram, ready for spots to be added
  sub plot_outline {
	  my $self = shift;
    my $image = shift;
    my $scale = $self->scale;
    ## first allocated colour is set to background
    my $grey = $image->colorAllocate(180,180,180);
	  my $aM   = $self->ch1_values;
    my $aA   = $self->ch2_values;
    my ($m_min,$m_max,$m_range) = $self->data_range($aM);
    my ($a_min,$a_max,$a_range) = $self->data_range($aA);
    my $middle = $self->middle;
	  my $x_length = $self->x_length;
	  my $y_length = $self->y_length;
	  my $x_margin = $self->x_margin;
    my $y_margin = $self->y_margin;
	  # get colours from the GD colour table 
	  my $black = $image->colorExact(0,0,0);
	  ## x axis
	  $image->line(50,$y_length+50,$x_length+50,$y_length+50,$black);
	  ## y axis
	  $image->line(50,50,50,$y_length+50,$black);
	  ## x axis label
	  my $x_max_label = int($a_max);
	  my $y_max_label = int($m_max);
	  $image->string($image->gdGiantFont,($x_length+50)/2,$y_length+80,"Channel 1 Intensity",$black);
	  $image->string($image->gdGiantFont,50,$y_length+50,"0",$black);
	  $image->string($image->gdGiantFont,$x_length+50,$y_length+50,"$x_max_label",$black);
    ## y axis label
	  $image->stringUp($image->gdGiantFont,10,$middle,"Channel 2 Intensity",$black);
	  $image->stringUp($image->gdGiantFont,30,$y_length+50,"0",$black);
	  $image->stringUp($image->gdGiantFont,30,50,"$y_max_label",$black);
  }
}
{ package heatmap;
  
  our @ISA = qw( plot );
  
  sub plot_dimensions {
    my $self  = shift;
    my $scale = $self->scale;
    my $aY    = $self->y_coords;
    my $aX    = $self->x_coords;
    my ($y_min,$y_max,$y_range) = $self->data_range($aY);
    my ($x_min,$x_max,$x_range) = $self->data_range($aX);
    my $x = int($x_max / $scale);
    my $y = int($y_max / $scale);
    $self->{ _x_length } = $x;
    $self->{ _y_length } = $y;
    $self->{ _x_margin } = int($x_min / $scale)/2;
    $self->{ _y_margin } = int($y_min / $scale)/2;
    return($x, $y);
  }
  sub plot_values {
    my $self = shift;
    my $aX = $self->x_values;
    my $aY = $self->y_values;
    my $scale  = $self->scale;
    my $x_margin = $self->x_margin;
    my $y_margin = $self->y_margin;
    my $aXadjusted = [];
    my $aYadjusted = [];
    for (my $i=0; $i<@$aX; $i++){
      my $x = $aX->[$i];
		  my $y = $aY->[$i];
		  next unless ($x && $y);
      $x = int(($x / $scale) - $x_margin);
		  $y = int(($y / $scale) - $y_margin);
      push(@$aXadjusted, $x);
      push(@$aYadjusted, $y);  
    }
    $self->{ _plotx_values } = $aXadjusted;
    $self->{ _ploty_values } = $aYadjusted;
  }
}
{ package log2_heatmap;

  our @ISA = qw( heatmap );
  
  sub process_data {
    my $self = shift;
    my $aCh1 = $self->ch1_values;
    my $aCh2 = $self->ch2_values;
    my $aRatio = [];
    for (my $i=0; $i<@$aCh1; $i++){
      my $ch1 = $aCh1->[$i];
		  my $ch2 = $aCh2->[$i];
      next unless ($ch1 && $ch2);
      push(@$aRatio, log($ch1/$ch2)/log(2));
    }
    $self->{ _x_values } = $aCh1;
    $self->{ _y_values } = $aCh2;
    $self->{ _ratio_values } = $aRatio;
  }
  sub plot_outline {
	  my $self = shift;
    my $plot = shift;
    ## first allocated colour is set to background
    my $black = $plot->colorAllocate(180,180,180);
  }
  sub plot_spots {
	  my $self = shift;
    my $plot = shift;
    my $aXcoords = $self->x_coords;
    my $aYcoords = $self->y_coords;
    my $aRatio   = $self->ratio_values;
    my $scale    = $self->scale;
    my $x_margin = $self->x_margin;
    my $y_margin = $self->y_margin;
	  $self->make_colour_grads($plot);
	  for (my $i=0; $i<@$aXcoords; $i++){
		  my $x = $aXcoords->[$i];
		  my $y = $aYcoords->[$i];
		  my $ratio = $aRatio->[$i];
      next unless ($x && $y && $ratio);
      $x = int(($x / $scale) - $x_margin);
		  $y = int(($y / $scale) - $y_margin);
			my $colour = $self->get_colour($plot,$ratio);
			$plot->setPixel($x,$y,$colour);
    }
  }
  sub get_colour {
    my $self  = shift;
    my $plot  = shift;
    my $ratio = shift;
		my $colour;
		if ($ratio <= -1.1){
		  $colour = $plot->colorExact(255,0,0);
		} elsif ($ratio >= 1.1){
		    $colour = $plot->colorExact(0,255,0); 
		  } elsif ((0.1 > $ratio)&&($ratio > -0.1)) {
			    $colour = $plot->colorExact(255,255,0);
		    } elsif ($ratio >= 0.1) {
            my $red_hue = 255 - (255 * ($ratio - 0.1));
            $colour = $plot->colorClosest($red_hue,255,0);		# reducing red, closer to green
		      } else {
              my $green_hue = 255 + (255 * ($ratio + 0.1));
			        $colour = $plot->colorClosest(255,$green_hue,0);	# reducing green, closer to red
		        }
		return($colour);
	}  
}
{ package intensity_heatmap;

  our @ISA = qw( heatmap );
  
  sub plot_outline {
	  my $self = shift;
    my $plot = shift;
    ## first allocated colour is set to background
    my $black = $plot->colorAllocate(0,0,0);
  }
  sub plot_spots {
	  my $self = shift;
    my $plot = shift;
    my $aXcoords = $self->x_coords;
    my $aYcoords = $self->y_coords;
    my $scale    = $self->scale;
    my $x_margin = $self->x_margin;
    my $y_margin = $self->y_margin;
    my $aValues  = $self->ch1_values;
    #if ($self->channel == 1) {
    #  $aValues = $self->ch1_values;
    #} elsif ($self->channel == 2) {
    #    $aValues = $self->ch2_values;
    #  }
	  $self->make_colour_grads($plot);
	  for (my $i=0; $i<@$aXcoords; $i++){
		  my $x = $aXcoords->[$i];
		  my $y = $aYcoords->[$i];
		  my $value = $aValues->[$i];
      next unless ($x && $y && $value);
      $x = int(($x / $scale) - $x_margin);
		  $y = int(($y / $scale) - $y_margin);
		  my $colour = $self->get_colour($plot, $value);
	 		$plot->setPixel($x,$y,$colour);
    }
  }
  sub get_colour {
    my $self  = shift;
    my $plot  = shift;
    my $value = shift;
    my $colour;
    if ($value == 0) {  ## if the value is 0 colour black
      $colour = $plot->colorExact(0,0,0);
    } elsif ($value <= 13000) {  ## colour towards blue
        my $blue_hue = $value / 50.9;
        $colour = $plot->colorClosest(0,0,$blue_hue);  
      } elsif ($value <= 26000) {  ## colour towards turquoise
          my $turquoise_hue = ($value - 13000) / 50.9;
          $colour = $plot->colorClosest(0,$turquoise_hue,255);  
        } elsif ($value <= 39000) {  ## colour towards green
            my $green_hue = ($value - 26000) / 50.9;
            $colour = $plot->colorClosest(0,255,255-$green_hue);  
          } elsif ($value <= 52000) {  ## colour towards yellow
              my $yellow_hue = ($value - 39000) / 50.9;
              $colour = $plot->colorClosest($yellow_hue,255,0);  
            } elsif ($value < 65000) {  ## colour towards red
                my $red_hue = ($value - 52000) / 50.9;
                $colour = $plot->colorClosest(255,255-$red_hue,0);  
              } elsif ($value >= 65000) {  ## if value is saturated colour white
                  $colour = $plot->colorExact(255,255,255);
                }
		return($colour);
	}
  # set a rainbow of graduated colours in the GD colour table, for use in the plot 
  sub make_colour_grads {
	  my $self  = shift;
    my $image = shift;
    my $count = 0;
    for (my $i = 0; $i<=255; $i+=5){ 	
      $image->colorAllocate(0,0,$i);        ## Add blue up to 255 -> blue
		  $image->colorAllocate(0,$i,255);      ## Add green up to 255 -> turquise
		  $image->colorAllocate(0,255,255-$i);  ## Reduce blue -> green
		  $image->colorAllocate($i,255,0);      ## Add red up to 255 -> yellow
		  $image->colorAllocate(255,255-$i,0);  ## Reduce green -> red
	  }	
  }
}

1;

__END__

=head1 NAME

TRL::Microarray::Image - A Perl module for creating microarray data plots

=head1 SYNOPSIS

	use TRL::Microarray::Image;

=head1 DESCRIPTION

TRL::Microarray::Image is an object-oriented Perl module for creating microarray data plots.

=head1 METHODS

To be added

=head1 SEE ALSO

TRL::Microarray

=head1 AUTHOR

James Morris, Translational Research Laboratories, Institute for Women's Health, University College London.

james.morris@ucl.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by James Morris, University College London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
