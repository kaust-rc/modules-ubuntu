#%Module 1.0 -*- tcl -*-
#
#  Module for use with 'environment-modules' package:
#

source [file dirname $::ModulesCurrentModulefile]/../../common/common_setup2.tcl 
#set       ::dir_name         r
GeneralAppSetup

# Prereqs
prereq gcc 
prereq blas


# Specific setup goes here, license files, path setup, etc
prepend-path PATH $app_dir/bin
prepend-path LD_LIBRARY_PATH $app_dir/lib64
prepend-path MANPATH $app_dir/share
#setenv LM_LICENSE_FILE $app_dir/license.dat





