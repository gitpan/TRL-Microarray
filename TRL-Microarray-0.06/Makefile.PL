use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'TRL::Microarray',
    VERSION_FROM      => 'lib/TRL/Microarray.pm', # finds $VERSION
    PREREQ_PM         => {  Image::ExifTool => 6.66, 
    						GD => 2.32,
    						GD::Image => 2.27,
    						Statistics::Descriptive => 2.6
    					},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/TRL/Microarray.pm', # retrieve abstract from module
       AUTHOR         => 'Christopher Jones <c.jones@ucl.ac.uk>') : ()),
);
