Integration of trackers
=======================

Introduction
------------

This file describes the process of tracker integration into the VOT toolkit evaluation environment. When designing the integration interface the main goal was that the adaptation of a tracker should be as simple as possible for as many programming languages and operating systems as possible and that the separation between the evaluation logic and the tracker should be very clear.

Basic idea
----------

A tracker is written as a GUI-less executable or a script that receives its input data from a known location on the hard-drive and outputs its result to a known location on the hard-drive and then terminates.

Every time the tracker is run, the toolkit generates a new temporary directory and populates it with the input data. The tracker is then executed in this (working) directory.

**Input**: There are two input files available in the working directory:

* `images.txt` - A text file containing a new-line separated list of absolute file paths. Each line therefore determines an image file on the hard-drive. Images are in JPEG format. Note that no assumptions should be made regarding the names of the files. The only legal order of the images is the one provided in the file.

* `region.txt` - A text file containing four comma-separated values that denote the left,top coordinate of the initial object bounding-box as well as its width and height.

**Output**: In order to consider a tracker execution as successful the tracker has to produce a `output.txt` file before it exits. This file should contain a sequence of object's bounding-boxes that correspond to the appropriate frames in the input image sequence. The bounding-box sequence is encoded as a comma-separated list of four values per frame:

    <left_1>,<top_1>,<width_1>,<height_1>
    <left_2>,<top_2>,<width_2>,<height_2>
    <left_3>,<top_3>,<width_3>,<height_3>
    <left_4>,<top_4>,<width_4>,<height_4>
    ...

Note that each line corresponds to a single frame and only a single bounding box should be outputted by the tracker per each frame. Please not that the tracker is required to produce the bounding box for each frame and it is up to tracker to decide how to predict that frame in case it does not detect any target. The most naive output in such situation, for example, would be setting the bounding box to the size of the entire image with its center corresponding to the center of the image.

Binary trackers
---------------

For trackers that are compiled into a binary executable form languages, such as C or C++ the integration is simple. The tracker should be able to read and write text files as described in the previous section. Several examples of such trackers are provided with the VOT toolkit with utility functions that can be copied to ones code to ease the adaptation process. 

To register a binary tracker in the environment, simply set the `tracker_command` variable value in the `configuration.m` to the full absolute path to the executable (optionally together with required parameters if the tracker requires some).

**Linking problems**: In some cases the executable requires access to some additional libraries, found in non-standard directories. Matlab overrides the default linking path environmental variable, which can cause linking problems in some cases. For this we have introduced a `tracker_linkpath` variable in the `configuration.m`. This variable should be a cell-array of all directories that should be included in the linking path. An example below adds two custom directories to the library path list in Linux:

    tracker_linkpath = {'/usr/lib64/qt4/', '/usr/lib64/opencv/'};

Matlab trackers
---------------

Matlab-based trackers are a bit more tricky to integrate as the scripts are typically run in an integrated development environment. In order to integrate a Matlab tracker into the evaluation, a wrapper function has to be created. This function will usually read the input files, but more importantly it should call `exit` command at the end in order to terminate Matlab interpreter completely. This is very important as the toolkit waits for the tracker executable to stop before it continues with the evaluation of the generated results. Another issue that has to be addressed is the user-issued termination. When a `Ctrl+C` command is issued during the `system` call the command is forwarded to the child process. Because of this the child Matlab will break the execution and return to interactive mode. In order to tell Matlab to quit in this case we can use the [onCleanup](http://www.mathworks.com/help/matlab/ref/oncleanup.html) function which also addresses the normal termination scenario:

	function wrapper()
		onCleanup(@() exit() ); % Tell Matlab to exit once the function exits
		... tracking code ...

 For an example of integration please check out the Matlab tracker example in the `examples` directory.

When specifying the `tracker_command` variable in the configuration file please note that the wrapper script file is not the one being executed but only a parameter to the Matlab executable. The actual command therefore looks like this:

    tracker_command = '<TODO: path to Matlab executable> -nodesktop -nosplash [-wait] -r <TODO: name of the wrapper script>';

_Windows specific parameters_: The parameter `-wait` forces Matlab to wait for the script that was executed to finish before returning control to the toolkit and is required when running Matlab trackers on Windows.

It is important that all the directories containing required Matlab scripts are contained in the MATLAB path when the evaluation is run. Also note that any unhandled exception thrown in the script will result in Matlab breaking to interactive mode and that this will prevent the evaluation from continuing. It is therefore advised that all exceptions are handled explicitly so that the wrapper script always terminates the interpreter.

Integration rules
-----------------

To make the tracker evaluation fair we list several rules that you should be aware of:

* _Stochastic processes_ - Many trackers use pseudo-random sampling at certain parts of the algorithm. To properly evaluate such trackers the random seed should not be fixed to a certain value. The best way to ensure this is to initialize seed with a different value every time, for example using current time. In C this is done by calling `srandom(time(NULL))` at the beginning of the program, while one way of doing this in Matlab is by calling:

	RandStream.setGlobalStream(RandStream('mt19937ar', 'Seed', sum(clock)));

* _Image stream_ - The tracking scenario specifies input images as a stream. Therefore the tracker should always only access images in the specified order and not skip ahead. 
* _Tracker parameters_ - The tracker is supposed to be executed with the same set of parameters on all the sequences. Any effort to determine the parameter values that were pre-tuned to a specific challenge sequence from the given images is prohibited.
* _Resources access_ - The tracker program should only access the files in the directory that it is executed in (that is `images.txt` and `region.txt`).

While we cannot enforce these guidelines in the current toolkit, the adherence of these rules is mandatory. Any violation is considered as cheating and could result in disqualification from the challenge.

Testing integration
-------------------

It is not recommended to immediately run the entire evaluation without testing the integration on a simpler task. For this the toolkit provides the `do_test` function that provides an interactive environment for testing your tracker on various sequences.

Using this environment you can verify the correct interpretation of input and output data (at the moment the interactive visualization only works in Matlab) as well as estimate the entire evaluation time based on several runs of the tracker on various sequences (run the tracker on several sequences, then select the option to display required estimate).
