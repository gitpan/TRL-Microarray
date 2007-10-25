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

{ package cgh_plot;
  
  our @ISA = qw( plot );

  sub get_data {
    my $self  = shift;
    my $db_id = shift;
    my $chr   = shift;
    use TRL::ArrayPipeLine;
    my $pipeline = pipeline->new_script() or exit;
    my $clone_source = $pipeline->default_clone_source;
    my $chr_name;
    if ($clone_source eq 'chori_bac_clone_info') {
      $chr_name = 'bcgsc_chromosome';
    } else {
        $chr_name = 'chromosome';
      }
    my $statement = "SELECT feature_name, log2_ratio, round((sequence_bp_start + sequence_bp_end)/2)
                     FROM processed_data, $clone_source 
                     WHERE processed_data_id = '$db_id'
                     AND log2_ratio != 'NULL'
                     AND $chr_name = '$chr' 
                     AND $clone_source.name = processed_data.feature_name
                     ORDER BY sequence_bp_start";
    my $aaData = $pipeline->sql_fetcharray_multirow($statement);
	  $self->{ _data } = $aaData;
    $self->sort_data;
    return($aaData);
  }
  sub sort_data {
    my $self = shift;
    my $aaData;
    if (@_) {
      $aaData = shift;  ## genome plot
    } else {
        $aaData = $self->data;  ## chromosome plot
      }
    my $aLocns = [];
    my $aLog2  = [];
    my $aNames = [];
    for my $row (@$aaData){
      my $name = $row->[0];
      my $log2 = $row->[1];
      my $locn = $row->[2];
      push(@$aLocns, $locn);
      push(@$aLog2,  $log2);
      push(@$aNames, $name);
    }
    $self->{ _x_values } = $aLocns;
    $self->{ _y_values } = $aLog2;
    $self->{ _feature_names } = $aNames;
    return($aLocns,$aLog2,$aNames);
  }
  sub make_plot {
    my $self  = shift;
    my $scale;
    if (@_) {
      $scale = shift;
    } else {
        $scale = 500000;
      }
    $self->{ _scale } = $scale;
    my ($x, $y) = $self->plot_dimentions;
    ## set the y value the same as the genome plot
    my $plot = GD::Image->new($x,$y);	
    $self->set_plot_background($plot);
    $self->make_colour_grads($plot);
	  $self->make_outline($plot);
    $self->plot_spots($plot);
    $self->{ _image } = $plot->png;
    return($plot->png);
  }
  # normalise the processed data relative to the image ready to be plotted
  sub plot_data {
    my $self = shift;
    my $aX = $self->x_values;
    my $aY = $self->y_values;
    my $scale    = $self->scale;
    my $middle   = $self->middle;
    my $x_margin = $self->x_margin;
    my $aLocns = [];
    my $aLog2  = [];
    for (my $i=0; $i<@$aX; $i++ ){
      my $locn = $aX->[$i];
      my $log2 = $aY->[$i];
      next unless($locn && $log2);
      push(@$aLocns, int($locn/$scale));
      ## divide the y axis by 3 for a +1.5/-1.5 plot
      push(@$aLog2, $middle - ($log2 * (450/3)));
    }
    $self->{ _plotx_values } = $aLocns;
    $self->{ _ploty_values } = $aLog2;
    return($aLocns,$aLog2);
  }
  sub plot_dimentions {
    my $self = shift;
    my $scale = $self->scale;
    my $aX   = $self->x_values;
    my ($x_min,$x_max,$x_range) = $self->data_range($aX);
    my $x = ($x_range /$scale);
    my $y = 450;
    my $x_margin = 0;
    my $y_margin = 0;
    $self->{ _x_length } = $x;
    $self->{ _y_length } = $y;
    $self->{ _x_margin } = $x_margin;
    $self->{ _y_margin } = $y_margin;
    $self->{ _middle } = ($y/2)+($y_margin/2) ;
    return(($x + $x_margin), ($y + $y_margin));
  }
  sub plot_spots {
	  my $self = shift;
    my $plot = shift;
    my $chr;
    if (@_) {
      $chr = shift;
    }
    my ($aX,$aY) = $self->plot_data($chr);
	  # get colour from the GD colour table
	  my $black = $plot->colorExact(0,0,0);
	  for (my $i=0; $i<@$aX; $i++){
      my $x = $aX->[$i];
		  my $y = $aY->[$i];
      next unless ($x && $y);
      my $colour = $self->get_colour($plot, $y);
      #$plot->setPixel($x,$y,$black);
			$plot->filledEllipse($x,$y,4,4,$colour);
	  }
  }
  # plot the outline of the diagram, ready for spots to be added
  sub make_outline {
	  my $self = shift;
    my $image = shift;
	  my $aX   = $self->plotx_values;
    my $aY   = $self->ploty_values;
    my ($x_min,$x_max,$x_range) = $self->data_range($aX);
    my ($y_min,$y_max,$y_range) = $self->data_range($aY);
    my $middle = $self->middle;
	  my $x_length = $self->x_length;
	  my $y_length = $self->y_length;
	  my $x_margin = $self->x_margin;
    my $y_margin = $self->y_margin;
	  # get colours from the GD colour table 
	  my $black = $image->colorExact(0,0,0);
	  my $red   = $image->colorExact(255,0,0);      
	  my $green = $image->colorExact(0,255,0);      
	  # 3px wide log2 ratio lines
	  $image->filledRectangle(0,150,3080,150,$red);		# +0.5
	  $image->filledRectangle(0,225,3080,225,$green);	#  0.0
	  $image->filledRectangle(0,300,3080,300,$red);		# -0.5
	  # axis labels
	  $image->string($image->gdGiantFont,10,150,'0.5',$black);
	  $image->string($image->gdGiantFont,10,225,'0',$black);
	  $image->string($image->gdGiantFont,10,300,'-0.5',$black);
  }	  
  # apply a moving avereage to the log2 data
  sub smooth_data_by_clone {
    my $self   = shift;
    my $window = shift;
    my $step   = shift;
    my $aX = $self->x_values;
    my $aY = $self->y_values;
    my $aSmooth_x = [];
    my $aSmooth_y = [];
    for (my $i=0; $i<(@$aX-($window-1)); $i+=$step){
      my $end = $i+($window-1);
      my @xslice = @$aX[$i..$i+($window-1)];
      my @yslice = @$aY[$i..$i+($window-1)];
      my $locn_sum = 0;
      my $log_sum = 0;
      foreach my $locn (@xslice) {
        $locn_sum += $locn;
      }
      foreach my $log (@yslice) {
        $log_sum += $log;
      }
      push(@$aSmooth_x, ($locn_sum/$window));
      push(@$aSmooth_y, ($log_sum/$window));
    }
    $self->{ _x_values } = $aSmooth_x;
    $self->{ _y_values } = $aSmooth_y;
    $self->{ _smoothed } = 1;
  }
  sub smooth_data_by_location {
    my $self   = shift;
    my $window = shift;
    my $step   = shift;
    my $alocns = $self->x_values;
    my $alogs  = $self->y_values;
    my @Locns  = ();
    my @Logs   = ();
    my $aSmooth_locns = [];
    my $aSmooth_logs = [];
    my($start,$end);
    for (my $i=0; $i<@$alocns; $i++){
      my $genomic_locn = $alocns->[$i];
		  my $log_value    = $alogs->[$i]; 
      unless ($start){
		    $start = $genomic_locn;
		    $end = $start + $window;
      }  
      if ($genomic_locn > $end){
		    my ($av_locn, $av_log) = $self->moving_average(\@Locns, \@Logs);
        push(@$aSmooth_locns, $av_locn);
        push(@$aSmooth_logs, $av_log);
		    while ($genomic_locn > $end){ 
          $end = (int($genomic_locn/100000) * 100000) + $step;
		      $start = $end - $window;
			    while ((@Locns) && ($Locns[0] < $start)){		# get rid of any values now out of the region 
				    my $shifted1 = shift @Locns;
				    my $shifted2 = shift @Logs;
			    }		
		    }
	    }
      push (@Locns, $genomic_locn);	# add the new values to the region
	    push (@Logs, $log_value);
    }
    my ($av_locn, $av_log) = $self->moving_average(\@Locns, \@Logs);
    push(@$aSmooth_locns, $av_locn);
    push(@$aSmooth_logs, $av_log);
    
	  $self->{ _x_values } = $aSmooth_locns;
    $self->{ _y_values } = $aSmooth_logs;
    $self->{ _smoothed } = 1;
  }
  sub moving_average {
	  my $self = shift;
	  my $Locns = shift;
	  my $Logs  = shift;
    my ($av_locn, $av_log2, $med_log2);
	  if (@$Locns > 1){
		  my $locn_stat = Statistics::Descriptive::Full->new();
		  my $log_stat = Statistics::Descriptive::Full->new();
		  $log_stat->add_data($Logs); 
		  $locn_stat->add_data($Locns); 
		  $av_locn = $locn_stat->mean;
		  $av_log2 = $log_stat->mean;
		  $med_log2 = $log_stat->median;
	    } elsif (@$Locns == 1){
		      $av_locn = @$Locns[0];
		      $av_log2 = @$Logs[0];
	      }
	  return($av_locn, $med_log2);
  }
  sub is_smoothed {
    my $self = shift;
    $self->{ _smoothed };
  }
  sub get_colour {
    my $self  = shift;
    my $plot  = shift;
    my $ratio = shift;
		# get colours from the GD colour table
	  my $red    = $plot->colorExact(255,0,0);      
	  my $green  = $plot->colorExact(0,255,0);      
	  my $yellow = $plot->colorExact(255,255,0);      
    my $colour;
    if ($ratio <= 150){
			$colour = $red;
		} elsif ($ratio >= 300){
			  $colour = $green;
		  } elsif ((262 > $ratio)&&($ratio > 187)) {
			    $colour = $yellow;
		    } elsif ($ratio >= 262) {
			      my $red_hue = 255-(2.55*($ratio-262));				# factorial = 255/(low_yellow - green)
			      $colour = $plot->colorClosest($red_hue,255,0);		# reducing red, closer to green
		      } else {
			        my $green_hue = 255-(2.55*(187-$ratio));				#`factorial = 255/(high_yellow - red)
			        $colour = $plot->colorClosest(255,$green_hue,0);	# reducing green, closer to red
		        }
		return($colour);
	}
	sub image_map {
    my $self      = shift;
    my $scale     = shift;
    my $link      = shift;   
    my $aX        = $self->x_values;
    my $aY        = $self->y_values;
    my $aFeatures = $self->feature_names;
    my $middle    = shift;
    print "<MAP NAME=\"Map_one\">";
    for (my $i=0; $i<@$aX; $i++){
		  my $x = $aX->[$i];
		  my $y = $aY->[$i];
		  my $feature = $aFeatures->[$i];
      next unless ($x && $y);
      $y = $middle - ($y * $scale);
		  $x = $x * $scale;
			print "<AREA SHAPE=\"Circle\" COORDS=\"$x,$y, 5\" HREF=$link>";
	  }
    print "</MAP>";
  }
}
{ package genome_cgh_plot;

  our @ISA = qw( cgh_plot );
  
  sub get_genome_data {
    my $self = shift;
    my $db_id;
    if (@_) {
      $db_id = shift;
    }
    unless (defined $self->{ _genome_data }){
      $self->set_genome_data($db_id);
		}
		$self->{ _genome_data };
  }
  sub set_genome_data {
    my $self  = shift;
    my $db_id = shift;
    my @genome_data;
    for my $chr (1..22,'x','y') {
      my $aaData = $self->get_data($db_id, $chr);
      push(@genome_data, $aaData);
    }
    $self->{ _genome_data } = \@genome_data;
  }
  sub make_plot {
    my $self  = shift;
    my $db_id = shift;
    my $window = '';
    my $step   = '';
    if (@_) {
      $window = shift;
      $step   = shift;
    }
    ## set scale for the genome plot to 2.5Mb per pixel
    $self->{ _scale } = 2500000; 
    ## chr 25 is the total lenght of the genome plus 25 margin
    my $x_axis = ($self->chr_offset(25)/$self->scale)+25;
    my $plot = GD::Image->new($x_axis,450);	
	  $self->set_plot_background($plot);
    $self->make_colour_grads($plot);
    $self->make_outline($plot);
    my $aGenomeData = $self->get_genome_data($db_id);
    for (my $i=0; $i<@$aGenomeData; $i++ ){
      my $chr = $i+1;
      $self->sort_data($aGenomeData->[$i]);
      if ($window && $step) {
        $self->smooth_data_by_location($window, $step);
      }
      $self->plot_spots($plot, $chr);
    }
    $self->{ _image } = $plot->png;
    return($plot->png);
  }
  sub plot_data {
    my $self = shift;
    my $chr  = shift;
    my $scale = $self->scale;
    my $aX = $self->x_values;
    my $aY = $self->y_values;
    my $chr_offset = $self->chr_offset($chr);
    my $aLocns = [];
    my $aLog2  = [];
    for (my $i=0; $i<@$aX; $i++ ){
      my $locn = $aX->[$i];
      my $log2 = $aY->[$i];
      next unless($locn && $log2);
      push(@$aLocns, int($locn/$scale)+ ($chr_offset/$scale)+ 25);
      ## multiply the log value by a quater of the y axis to get a +2/-2 plot  
      push(@$aLog2, 225 - ($log2 * (450/3)));
    }
    $self->{ _plotx_values } = $aLocns;
    $self->{ _ploty_values } = $aLog2;
    return($aLocns,$aLog2);
  }
  # Harcode the plot outline for the genome plot as dimentions do not change
  sub make_outline {
	  my $self = shift;
    my $image = shift;
    my $scale = $self->scale;
	  # get colours from the GD colour table 
	  my $black = $image->colorExact(0,0,0);
	  my $red   = $image->colorExact(255,0,0);      
	  my $green = $image->colorExact(0,255,0);      
	  # 3px wide log2 ratio lines
	  $image->filledRectangle(0,150,3080,150,$red);		# +0.5
	  $image->filledRectangle(0,225,3080,225,$green);	#  0.0
	  $image->filledRectangle(0,300,3080,300,$red);		# -0.5
	  # axis labels
	  $image->string($image->gdSmallFont,0,150,'0.5',$black);
	  $image->string($image->gdSmallFont,0,225,'0',$black);
	  $image->string($image->gdSmallFont,0,300,'-0.5',$black);
	  # plot chr separator lines and chr names for each chromosome
	  for my $chr ((1..24)){
		  my $start  = int($self->chr_offset($chr)/$scale);
		  my $end 	 = int($self->chr_offset($chr+1)/$scale);
		  my $middle = int(($start+$end)/2);
		  ## chr buffer
		  $image->filledRectangle($start+25,0,$start+25,450,$black);
		  # set chr names
		  my $chr_name;
		  if ($chr == 23){
			  $chr_name = 'X';
		  } elsif ($chr == 24){
			   $chr_name = 'Y';
			# end line
			$image->line($end+25,0,$end+25,450,$black);
		} else {
			$chr_name = $chr;
		}
		# print chr name at bottom of plot
		$image->string($image->gdSmallFont,$middle+25,425,$chr_name,$black);
	}
  }
  sub get_colour {
    my $self  = shift;
    my $plot  = shift;
    my $ratio = shift;
		# get colours from the GD colour table
	  my $red    = $plot->colorExact(255,0,0);      
	  my $green  = $plot->colorExact(0,255,0);      
	  my $yellow = $plot->colorExact(255,255,0);      
    my $colour;
    if ($ratio <= 150){
			$colour = $red;
		} elsif ($ratio >= 300){
			  $colour = $green;
		  } elsif ((262 > $ratio)&&($ratio > 187)) {
			    $colour = $yellow;
		    } elsif ($ratio >= 262) {
			      my $red_hue = 255-(2.55*($ratio-262));				      # factorial = 255/(low_yellow - green)
			      $colour = $plot->colorClosest($red_hue,255,0);		  # reducing red, closer to green
		      } else {
			        my $green_hue = 255-(2.55*(187-$ratio));				  # factorial = 255/(high_yellow - red)
			        $colour = $plot->colorClosest(255,$green_hue,0);	# reducing green, closer to red
		        }
		return($colour);
	}
  sub genome_data {
    my $self = shift;
    $self->{ _genome_data };
  }
  sub chr_offset {
    my $self = shift;
    my $chr  = shift;
    my %hChromosome = (		
		  # start bp  			# length
		  1 => 0,   				# 247249719
		  2 => 247249720,		# 242951149
		  3 => 490200869,		# 199501827
		  4 => 689702696,		# 191273063
		  5 => 880975759,		# 180857866
		  6 => 1061833625,	# 170899992
		  7 => 1232733617,	# 158821424
		  8 => 1391555041,	# 146274826
		  9 => 1537829867,	# 140273252
		  10 => 1678103119,	# 135374737
		  11 => 1813477856,	# 134452384
		  12 => 1947930240,	# 132349534
		  13 => 2080279774,	# 114142980
		  14 => 2194422754,	# 106368585
		  15 => 2300791339,	# 100338915
		  16 => 2401130254,	# 88827254
		  17 => 2489957508,	# 78774742
		  18 => 2568732250,	# 76117153
		  19 => 2644849403,	# 63811651
		  20 => 2708661054,	# 62435964
		  21 => 2771097018,	# 46944323
		  22 => 2818041341,	# 49691432
		  23 => 2867732773,	# 154913754
		  24 => 3022646527,	# 57772954	TOTAL=3080419480
		  25 => 3080419480
	  );
	  return ($hChromosome{$chr});
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
