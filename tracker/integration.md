Tracker integration
===================

This file describes the details about the tracker integration into the VOT toolkit. It is not written as a quick integration guide, but rather as a technical document that provides a lot of details about the integration. For a quick tutorial on integration you should check the [integration tutorial](http://votchallenge.net/howto/integration.html).

When designing the integration interface the main goal was that the adaptation of a tracker should be as simple as possible for as many programming languages and operating systems as possible and that the separation between the evaluation logic and the tracker should be very clear. With the current version of the toolkit there is now only one way of integrating a tracker to the VOT toolkit evaluation environment, the [TraX protocol](https://github.com/votchallenge/trax/). The benefit of the protocol is faster and more flexibile execution of experiments. Since VOT2015 we are providing some common boilerplate code that makes it easy to transition form the previously supported file-based integration. Examples of using these wrappers are available in the toolkit repository.

## The TraX protocol

Tracking eXchange protocol is a simple protocol that enables easier evaluation of computer vision tracking algorithms. The basic idea is that a tracker communicates with the evaluation software using a set of textual commands over the standard input/output streams of each process.

Integration of TraX protocol into a C/C++ or Matlab tracker is quite simple as there are [examples](https://github.com/votchallenge/trax/tree/master/trackers) available in the repository of the reference implementation.

VOT toolkit is tightly connected to the TraX reference implementation as it shares some native code with it. For the execution the toolkit uses a `traxclient` MEX library to execute a tracker and control it. This way the tracker can be monitored and reinitialized when required. While the TraX reference implementation source code is automatically downloaded and compiled by the toolkit (if a MEX compiler is properly configured), the native TraX library that is used for C/C++ trackers has to be compiled manually using [CMake](http://www.cmake.org/). If possible, the toolkit also downloads pre-compiled version of the libraries, however, it has been reported that this approach does not work all the time.



