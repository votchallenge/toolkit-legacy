Utilities module
================

This module contains general utility functions that are used all over the toolkit.

Module functions
----------------

### Files

-   [parsefile](parsefile.m) - Parse a file to a cell array
-   [readstruct](readstruct.m) - Read a key-value file to a structure
-   [writestruct](writestruct.m) - Store a structure to file
-   [file_newer_than](file_newer_than.m) - Test if the first file is newer than the second file
-   [generate_from_template](generate_from_template.m) - Generate a new file from a template file
-   [delpath](delpath.m) - Deletes the file or directory recursively
-   [mkpath](mkpath.m) - Creates a directory path
-   [relativepath](relativepath.m) - Returns the relative path from an root path to the target path
-   [filewrite](filewrite.m) - Write a string to a file

### Figures

-   [plotc](is_octave.m) - Plot closed polygon
-   [sfigure](is_octave.m) - Silently creates a figure window
-   [export_figure](export_figure.m) - Export a figure to various formats

### General

-   [is_octave](is_octave.m) - Test if in GNU/Octave or Matlab
-   [iterate](iterate.m) - Iterates over experiment, tracker and sequence triplets
-   [iff](iff.m) - A simulation of inline conditional statement
-   [struct_merge](struct_merge.m) - Merges a from structure to another in a recursive manner
-   [format_interval](format_interval.m) - Format a time interval
-   [patch_operation](patch_operation.m) - Performs a point-wise operation with two unequal matrices
-   [initialize_native](initialize_native.m) - Initialize all native components
-   [compile_mex](compile_mex.m) - Compile given source files to a MEX function

### Strings

-   [md5hash](md5hash.m) - Calculate 128 bit MD5 checksum
-   [strjoin](strjoin.m) - Joins multiple strings
-   [strxcmp](strxcmp.m) - Advanced substring comparison
-   [json_encode](json_encode.m) - Encodes object to JSON string
-   [json_decode](json_decode.m) - Parses JSON string to an object

### Mathematics and statistics

-   [gmm_estimate](gmm_estimate.m) - Estimates a GMM on a set of points
-   [gmm_evaluate](gmm_evaluate.m) - Evaluates the GMM for a set of points
-   apcluster - Computers clusters on data using affinity propagation
