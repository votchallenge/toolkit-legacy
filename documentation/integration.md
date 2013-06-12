Integration of trackers
=======================

Introduction
------------

This file describes the process of tracker integration into the VOT toolkit evaluation environment. When designing the integration interface the main goal was that the adaptation of a tracker should be as simple as possible for as many programming languages and operating systems as possible and that the separation between the evaluation logic and the tracker should be very clear.

Terminology
-----------

For better understanding we begin with a definition of important terms related to integration:

* _Executable_
* _Working directory_
* _Image list_
* _Initial region_
* _Tracker output_

Basic idea
----------

A tracker is written as a GUI-less executable or a script that receives its input data from a known location on the hard-drive and outputs its result to a known location on the hard-drive and then terminates.

**Input**

TODO

**Output**

TODO

Binary trackers
---------------

For trackers that are compiled into a binary executable form languages, such as C or C++ the integration is simple. The tracker should be able to read and write text files as described in the previous section. Several examples of such trackers are provided with the VOT toolkit with utility functions that can be copied to ones code to ease the adaptation process. 

To register a binary tracker in the environment, simply set the `tracker_command` variable value in the `configuration.m` to the full absolute path to the executable (optionally together with required parameters if the tracker requires some).

Matlab trackers
---------------

TODO
