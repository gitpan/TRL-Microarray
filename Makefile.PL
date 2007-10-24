use 5.008001;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME              => 'TRL::Microarray',
    VERSION_FROM      => 'lib/TRL/Microarray.pm',
    PREREQ_PM         => {  Image::ExifTool => 6.66, 
    						GD => 2.32,
    						GD::Image => 2.27,
    						Statistics::Descriptive => 2.6,
							Test::More => 0.64,
							Test::Group => 0.07,
							Test::Differences => 0.47,
							Test::Deep => 0.096
    					},	# no apologies for including test module dependencies!
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'lib/TRL/Microarray.pm', 
       AUTHOR         => 'Christopher Jones <c.jones@ucl.ac.uk>') : ()),
);
