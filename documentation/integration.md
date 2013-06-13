Integration of trackers
=======================

Introduction
------------

This file describes the process of tracker integration into the VOT toolkit evaluation environment. When designing the integration interface the main goal was that the adaptation of a tracker should be as simple as possible for as many programming languages and operating systems as possible and that the separation between the evaluation logic and the tracker should be very clear.

Basic idea
----------

A tracker is written as a GUI-less executable or a script that receives its input data from a known location on the hard-drive and outputs its result to a known location on the hard-drive and then terminates.

Every time the tracker is run, the toolkit generates a new temporary directory and populates it with the input data. The tracker is then executed in this (working) directory.

**Input**

There are two input files available in the working directory:

* `images.txt` - A text file containing a new-line separated list of absolute file paths. Each line therefore determines an image file on the hard-drive. Images are in JPEG or PNG format. Note that no assumptions should be made regarding the names of the files. The only legal order of the images is the one provided in the file.

* `region.txt` - A text file containing four comma-separated values that denote the left,top coordinate of the initial object bounding-box as well as its width and height.

**Output**

In order to consider a tracker execution as successful the tracker has to produce a `output.txt` file before it exits. This file should contain a sequence of object's bounding-boxes that correspond to the appropriate frames in the input image sequence. The bounding-box sequence is encoded as a comma-separated list of four values per frame:

    <left_1>,<top_1>,<width_1>,<height_1>
    <left_2>,<top_2>,<width_2>,<height_2>
    <left_3>,<top_3>,<width_3>,<height_3>
    <left_4>,<top_4>,<width_4>,<height_4>
    ...

Binary trackers
---------------

For trackers that are compiled into a binary executable form languages, such as C or C++ the integration is simple. The tracker should be able to read and write text files as described in the previous section. Several examples of such trackers are provided with the VOT toolkit with utility functions that can be copied to ones code to ease the adaptation process. 

To register a binary tracker in the environment, simply set the `tracker_command` variable value in the `configuration.m` to the full absolute path to the executable (optionally together with required parameters if the tracker requires some).

Matlab trackers
---------------

Matlab-based trackers are a bit more tricky to integrate as the scripts are typically run in an integrated development environment. In order to integrate a Matlab tracker into the evaluation, a wrapper script has to be created. This script will usually read the input files, but more importantly it should call `exit` command at the end in order to terminate Matlab interpreter completely. This is very important as the toolkit waits for the tracker executable to exit before it continues. For the details please check out the Matlab tracker example in the `examples` directory.

When specifying the `tracker_command` variable in the configuration file please note that the wrapper script file is not the one being executed but only a parameter to the Matlab executable. The actual command therefore looks like this:

    tracker_command = '<TODO: path to Matlab executable> -nodesktop -nosplash -r <TODO: name of the wrapper script>';

Of course all the directories, containing required Matlab scripts should be registered with Matlab prior to running the evaluation. Also note that any unhandled exception thrown in the script will result in Matlab breaking to interactive mode and that this will prevent the evaluation from continuing. It is therefore advised that all exceptions are handled explicitly so that the wrapper script always terminates the interpreter.

