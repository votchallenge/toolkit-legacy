Tooklit overview and usage instructions
=======================================

Introduction
------------

This document describes the structure of the VOT toolkit code and its basic usage. To perform an evaluation you must have your tracker adapted to perform in a specified way (for this you should consult the `integration.md` guide).

Terminology
-----------

For better understanding we begin with a definition of important terms:

* _Tracker_ - The executable or a script containing a tracking algorithm that is evaluated. The tracker should be able to receive the input data and behave in a specified way.
* _Sequence_ - A single sequence of images with manually annotated ground-truth positions of the object used for evaluation.
* _Annotation_ - Manual or automatic description of visual position of the object. In the current toolkit the only type of supported annotation is a bounding-box, described as a series of four values denoting the left-top corner of the rectangle as well as its width and height.
* _Trajectory_ - A sequence of annotations that describes the motion of the object in the sequence. In the toolkit it is saved to a file in a CSV format.
* _Tracker run_ - A single execution of a tracker on an entire sequence or its subset. The tracker gets input information in terms of a list of images and an initial position of the object and produces a sequence of positions in the following images.
* _Trial_ - If a tracker fails during tracking it is reinitialized at the first point of failure
* _Repetition_ - To properly address the potential stochastic nature of the algorithm, several trials are performed on each sequence. Each trial is therefore called a repetition.
* _Experiment_ - Evaluation of a tracker on a set of sequences in specific conditions. Specific experiment may change the original sequences to simulate some specific kind of circumstances (e.g. noise).
* _Evaluation_ - Performing a set of experiments on a specific tracker.
* _Region overlap_ - Overlap distance between two regions, in our case this is usually the ground-truth bouning box and the tracker predicted bouning-box. Calculated as the intersection divided by union and therefore bounded between 1 and 0.
* _Performance measure_ 

Structure
---------

The evaluation source code resides in the `evaluation` directory and is structured into several subdirectories according to the main function of individual parts. The code is written in a pure Matlab language with a strong emphasis on Octave compatibility as well as support for multiple versions of Matlab (at the moment it was tested with versions from 2011 and 2012).

Set up the toolkit
------------------

In order to set up the toolkit, you have to copy the `configuration_template.m` to `configuration.m` and edit it to set the required variables.

The first variable that has to be set is an absolute path to a working directory. This is the directory where all the sequences and results are stored.

    track_properties.directory = '<TODO: set a working directory for sequences and results>';

Then the evaluated tracker has to be configured as well. This is done by setting an unique tracker identifier (used to determine the tracker at the VOT on-line result repository) as well as the exact executable command (consult the `integration.md` guide for details).

    tracker_identifier = '<TODO: set a tracker identifier>';
    
    tracker_command = '<TODO: set a tracker executable command>';

Perform an evaluation
---------------------

The entire evaluation is currently performed by executing the `do_experiments` script in Matlab or Octave. This script performs all the experiments, collects and analyzes result data and creates a result package that is ready for submission to the VOT website.

Submit the results
------------------

At the end of the evaluation the toolkit generates a ZIP file containing all the results. In order to publish the results to the VOT on-line result repository, this file has to be submitted to the repository maintainers (consult the on-line instructions at the repository website).

Additional configuration
------------------------

There are several non-essential parameters available in `configuration.m` file.

* `track_properties.debug` sets the debug output option (disabled by default). Using this option it is possible to get additional information regarding the progress of the evaluation, however, its usage is mainly indented for development purposes.
* `track_properties.cache` sets the result caching (enabled by default). By disabling this option all the results are generated every time the evaluation is run instead of preserving results for trials that were already successfully executed.
* `track_properties.pack` sets the result packaging (enabled by default). If enabled, the results of the evaluation are packed into a ZIP archive at the end of the evaluation. This file is ready to be submitted to the VOT on-line result repository.
