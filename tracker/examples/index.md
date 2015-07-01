Tracker integration examples
============================

Several examples of tracker integration for C/C++ and Matlab trackers are provided together with the toolkit. Helpers for both languages are provided so that integration is as easy as adding a few lines of code to your tracker source code. More details about the actual process of integration can be found [here](../integration.md).

C/C++
------------

Three examples are provided by the toolkit. There are two static trackers (trackers that just report the initial position) written in C and C++ and a NCC tracker written in C++ and using OpenCV library.

All three trackers are using `vot.h` header that provides integration functions and classes that can be used to speed up the integration process.

Matlab
------

A NCC tracker example, written in Matlab is provided by the toolkit. The tracker uses `vot` function that generates a communication structure that is then used to communicate with the toolkit.
