Tooklit overview and usage instructions
=======================================

Introduction
------------

This document describes the structure of the VOT toolkit code and its basic usage. To perform an evaluation you must have your tracker adapted to perform in a specified way (for this you should consult the `integration.md` guide).

Terminology
-----------

For better understanding we begin with a definition of important terms:

* Tracker
* Sequence
* Tracker run
* Trial
* Repetition
* Experiment
* Annotation
* Trajectory
* Overlap
* Measure

Structure
---------

The evaluation source code resides in the `evaluation` directory and is structured into several subdirectories according to the main function of individual parts. The code is written in a pure Matlab language with a strong emphasis on Octave compatibility as well as support for multiple versions of Matlab (at the moment it was tested with versions from 2011 and 2012).

Set up the toolkit
------------------

In order to set up the toolkit, you have to copy the `configuration_template.m` to `configuration.m` and edit it to set the required variables.

TODO

Perform an evaluation
---------------------

The entire evaluation is currently performed by executing the `do_experiments` script in Matlab or Octave. This script performs all the experiments, collects nad analyzes result data and creates a result package that is ready for submission to the VOT website.

Submit the results
------------------

TODO

Additional configuration
------------------------

There are several non-essential parameters available in `configuration.m` file.

TODO