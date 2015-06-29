Tracker integration
===================

This file describes the process of tracker integration into the VOT toolkit evaluation environment. When designing the integration interface the main goal was that the adaptation of a tracker should be as simple as possible for as many programming languages and operating systems as possible and that the separation between the evaluation logic and the tracker should be very clear.

With the current version of the toolkit there are now two ways of integrating a tracker to the VOT toolkit evaluation environment. There is the old way of communication using files and the new way of using the [TraX protocol](https://github.com/lukacu/trax/). The recommended and default way of integration with 2014 challenge is the TraX protocol, however, it requires some extra work. The benefit is faster execution of experiments and more flexibility.

TraX protocol
-------------
Tracking eXchange protocol is a simple protocol that enables easier evaluation of computer vision tracking algorithms. The basic idea is that a tracker communicates with the evaluation software using a set of textual commands over the standard input/output streams of each process.

Integration of TraX protocol into a C/C++ or Matlab tracker is quite simple as there are [examples](https://github.com/lukacu/trax/tree/master/trackers) available in the repository of the reference implementation. 

VOT toolkit is now tightly connected to the TraX reference implementation as it shares some native code with it. For the execution the toolkit uses a `traxclient` tool to execute a tracker. The tool acts as a wrapper that communicates with the tracker and reinitializes it when required. While the TraX source code is automatically downloaded by the toolkit (to the `trax` subdirectory in the toolkit source), the client executable as well as a native TraX library have to be compiled manually using [CMake](http://www.cmake.org/) and an appropriate compiler for your platform (we are working on automating this process, however, there are more urgent things that we have to do before). Once the client is compiled you have to specify the path to the executable in your workspace by adding the following line to the `configuration.m`:

    set_global_variable('trax_client', '<TODO: full path to the executable>');


File protocol
-------------
A tracker is written as a GUI-less executable or a script that receives its input data from a known location on the hard-drive and outputs its result to a known location on the hard-drive and then terminates. The limitation of this approach is that only bounding boxes may be used while the TraX protocol also supports more complex region descriptions.

Every time the tracker is run, the toolkit generates a new temporary directory and populates it with the input data. The tracker is then executed in this (working) directory.

**Input**: There are two input files available in the working directory:

* `images.txt` - A text file containing a new-line separated list of absolute file paths. Each line therefore determines an image file on the hard-drive. Images are in JPEG format. Note that no assumptions should be made regarding the names of the files. The only legal order of the images is the one provided in the file.

* `region.txt` - A text file containing comma-separated values that denote the initial region of the object. See [[Internals|internals]] document for more details about the format.

**Output**: In order to consider a tracker execution as successful the tracker has to produce a `output.txt` file before it exits. This file should contain a per-line list of object's regions that correspond to the appropriate frames in the input image sequence. Each region is encoded as a comma-separated list. There are two region formats available, a rectangle (four values) and a polygon (even number of six or more values), for details about both please check out the [[Internals|internals]] document.

Note that each line corresponds to a single frame and only a single region should be outputted by the tracker for each frame. Also note that the tracker is required to produce a valid region for each frame and it is up to the tracker to decide how to predict that frame in case it does not detect any target. The most naive output in such situation, for example, would be setting the bounding box to the size of the entire image with its center corresponding to the center of the image.

For trackers that are compiled into a binary executable form languages, such as C or C++ the integration is simple. The tracker should be able to read and write text files as described in the previous section. Several examples of such trackers are provided with the toolkit (in the `tracker/examples` directory together with some utility code that can be copied to ones code to ease the adaptation process. 

Binary trackers
---------------
To register a binary tracker in the environment, simply set the `tracker_command` variable value in the `tracker_<tracker_identifier>.m` to the full absolute path to the executable (optionally together with required parameters if the tracker requires some).

**Linking problems**: In some cases the executable requires access to some additional libraries, found in non-standard directories. Matlab overrides the default linking path environmental variable, which can cause linking problems in some cases. For this we have introduced a `tracker_linkpath` variable. This variable should be a cell-array of all directories that should be included in the linking path. An example below adds two custom directories to the library path list in Linux:

    tracker_linkpath = {'/usr/lib64/qt4/', '/usr/lib64/opencv/'};

Matlab trackers
---------------
Matlab-based trackers are a bit more tricky to integrate as the scripts are typically run in an integrated development environment. In order to integrate a Matlab tracker into the evaluation, a wrapper function has to be created. This function will usually read the input files, process it and write the output data. In case of the old integration approach is it is important that the `exit` command is called at the end in order to terminate Matlab interpreter completely. This is very important as the toolkit waits for the tracker executable to stop before it continues with the evaluation of the generated results. Another issue that has to be addressed is the user-issued termination. When a `Ctrl+C` command is issued during the `system` call the command is forwarded to the child process. Because of this the child Matlab will break the execution and return to interactive mode. In order to tell Matlab to quit in this case we can use the [onCleanup](http://www.mathworks.com/help/matlab/ref/oncleanup.html) function which also addresses the normal termination scenario:

	function wrapper()
		cleanup = onCleanup(@() exit() ); % Tell Matlab to exit once the function exits
		... tracking code ...

 For an example of integration please check out the Matlab tracker example in the `examples` directory. Note that this precautions are not needed in the new system as the TraX client takes care of termination (it can also stop a tracker process if a timeout is reached).

When specifying the `tracker_command` variable in the tracker configuration file please note that the wrapper script file is not the one being executed but only a parameter to the Matlab executable. The actual command therefore looks like this:

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
* _Resources access_ - The tracker program should only access the files in the directory that it is executed in.

While we cannot enforce these guidelines in the current toolkit, the adherence of these rules is mandatory. Any violation is considered as cheating and could result in disqualification from the challenge.

Testing integration
-------------------

It is not recommended to immediately run the entire evaluation without testing the integration on a simpler task. For this the toolkit provides the `vot_test` function that provides an interactive environment for testing your tracker on various sequences.

Using this environment you can verify the correct interpretation of input and output data (at the moment the interactive visualization only works in Matlab) as well as estimate the entire evaluation time based on several runs of the tracker on various sequences (run the tracker on several sequences, then select the option to display required estimate).

