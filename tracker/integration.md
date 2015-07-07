Tracker integration
===================

This file describes the details about the tracker integration into the VOT toolkit. It is not written as a quick integration guide, but rather as a technical document that provides a lot of details about the integration. For a quick tutorial on integration you should check the [integration tutorial](http://votchallenge.net/howto/integration.html).

When designing the integration interface the main goal was that the adaptation of a tracker should be as simple as possible for as many programming languages and operating systems as possible and that the separation between the evaluation logic and the tracker should be very clear. With the current version of the toolkit there are now two ways of integrating a tracker to the VOT toolkit evaluation environment. There is the old way of communication using files and the new way of using the [TraX protocol](https://github.com/votchallenge/trax/). The recommended and default way of integration with VOT2014 challenge is the TraX protocol, however, it requires some extra work. The benefit is faster execution of experiments and more flexibility. Since VOT2015 we are now providing common boilerplate code that switches between the two protocols with minimal human intervention, using the legacy one as a fallback option. Examples of using these wrappers are available in the toolkit repository.

## TraX protocol

Tracking eXchange protocol is a simple protocol that enables easier evaluation of computer vision tracking algorithms. The basic idea is that a tracker communicates with the evaluation software using a set of textual commands over the standard input/output streams of each process.

Integration of TraX protocol into a C/C++ or Matlab tracker is quite simple as there are [examples](https://github.com/votchallenge/trax/tree/master/trackers) available in the repository of the reference implementation. 

VOT toolkit is now tightly connected to the TraX reference implementation as it shares some native code with it. For the execution the toolkit uses a `traxclient` tool to execute a tracker. The tool acts as a wrapper that communicates with the tracker and reinitializes it when required. While the TraX source code is automatically downloaded by the toolkit (to the `trax` subdirectory in the toolkit source), the client executable as well as a native TraX library have to be compiled manually using [CMake](http://www.cmake.org/) and an appropriate compiler for your platform (we are working on automating this process, however, there are more urgent things that we have to do before). Once the client is compiled you have to specify the path to the executable in your workspace by adding the following line to the `configuration.m`:

    set_global_variable('trax_client', '<TODO: full path to the executable>');

## File protocol

A tracker is written as a GUI-less executable or a script that receives its input data from a known location on the hard-drive and outputs its result to a known location on the hard-drive and then terminates. The limitation of this approach is that only bounding boxes may be used while the TraX protocol also supports more complex region descriptions.

Every time the tracker is run, the toolkit generates a new temporary directory and populates it with the input data. The tracker is then executed in this (working) directory.

**Input**: There are two input files available in the working directory:

* `images.txt` - A text file containing a new-line separated list of absolute file paths. Each line therefore determines an image file on the hard-drive. Images are in JPEG or PNG format. Note that no assumptions should be made regarding the names of the files. The only legal order of the images is the one provided in the file.

* `region.txt` - A text file containing comma-separated values that denote the initial region of the object.

**Output**: In order to consider a tracker execution as successful the tracker has to produce a `output.txt` file before it exits. This file should contain a per-line list of object's regions that correspond to the appropriate frames in the input image sequence. Each region is encoded as a comma-separated list. There are two region formats available, a rectangle (four values) and a polygon (even number of six or more values).

Note that each line corresponds to a single frame and only a single region should be outputted by the tracker for each frame. Also note that the tracker is required to produce a valid region for each frame and it is up to the tracker to decide how to predict that frame in case it does not detect any target. The most naive output in such situation, for example, would be setting the bounding box to the size of the entire image with its center corresponding to the center of the image.

For trackers that are compiled into a binary executable form languages, such as C or C++ the integration is simple. The tracker should be able to read and write text files as described in the previous section. Several examples of such trackers are provided with the toolkit (in the `tracker/examples` directory together with some utility code that can be copied to ones code to ease the adaptation process. 

