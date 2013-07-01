Overview and usage instructions
===============================

Introduction
------------

This document describes the structure of the VOT toolkit code and its basic usage. To perform an evaluation you must have your tracker adapted to perform in a specified way. For this you should consult the `integration.md` guide. For a detailed overview of the toolkits structure consult the `internals.md` guide.

Terminology
-----------

For better understanding we begin with a definition of important terms:

* _Tracker_ - The executable or a script containing a tracking algorithm that is evaluated. The tracker should be able to receive the input data and behave in a specified way.
* _Sequence_ - A single sequence of images with manually annotated ground-truth positions of the object used for evaluation.
* _Annotation_ - Manual or automatic description of visual position of the object. In the current toolkit the only type of supported annotation is a bounding-box, described as a series of four values denoting the left-top corner of the rectangle as well as its width and height.
* _Trajectory_ - A sequence of annotations that describes the motion of the object in the sequence. In the toolkit it is saved to a file in a CSV format.
* _Tracker run_ - A single execution of a tracker on an entire sequence or its subset. The tracker gets input information in terms of a list of images and an initial position of the object and produces a sequence of positions in the following images.
* _Trial_ - If a tracker fails during tracking it is reinitialized after the first point of failure.
* _Repetition_ - To properly address the potential stochastic nature of the algorithm, several trials are performed on each sequence. Each trial is therefore called a repetition.
* _Experiment_ - Evaluation of a tracker on a set of sequences in specific conditions. Specific experiment may change the original sequences to simulate some specific kind of circumstances (e.g. noise).
* _Evaluation_ - Performing a set of experiments on a specific tracker.
* _Region overlap_ - Overlap distance between two regions, in our case this is usually the ground-truth bouning box and the tracker predicted bouning-box. Calculated as the intersection divided by union and therefore bounded between 1 and 0.

Directory structure
-------------------

The code and the documents are organized in the following directory structure:

* `documentation` - Contains documentation files
* `evaluation` - contains the evaluation toolkit
* `examples` - Contains example source code in various languages

The evaluation source code resides in the `evaluation` directory and is structured into several subdirectories according to the main function of individual parts. 

Platform support
----------------

The code is written in a pure Matlab language with a strong emphasis on Octave compatibility as well as support for multiple versions of Matlab (at the moment it was tested with versions from 2011 to 2013).

The code should work on Windows, Linux and OSX, however, it is hard to verify this on all versions and system configurations. If you therefore find that there are some issues on your computer setup, submit a bug report at [Github](https://github.com/vicoslab/vot-toolkit/issues/new) as soon as possible.

Set up the toolkit
------------------

In order to set up the toolkit, you have to copy the `configuration_template.m` to `configuration.m` and edit it to set the required variables.

The first variable that has to be set is an absolute path to a working directory. This is the directory where all the sequences and results are stored.

    track_properties.directory = '<TODO: set a working directory>';

Then the evaluated tracker has to be configured as well. This is done by setting an unique tracker identifier (used to determine the tracker at the VOT on-line result repository) as well as the exact executable command (consult the `integration.md` guide for details).

    tracker_identifier = '<TODO: set a tracker identifier>';
    
    tracker_command = '<TODO: set a tracker executable command>';

Working directory
-----------------

Working directory is a directory where the toolkit stores sequences, results and cached data. It is recommended that the directory is empty before the first use, however, it can be used for multiple trackers later on. For more information regarding the directory structure consult the `internals.md` guide.

Perform tracker evaluation
--------------------------

The entire evaluation is currently performed by executing the `do_experiments` script in Matlab or Octave. This script performs all the experiments, collects and analyzes result data and creates a result package that is ready for submission to the VOT website.

The time required for the evaluation depends on the speed of your tracker. Because of the rigorous testing methodology the entire evaluation can take up to several days. For a more detailed explanation of the testing procedure consult the `internals.md` guide.

View and submit the results
---------------------------

At the end of the evaluation the toolkit generates a ZIP file containing all the raw results and an overview HTML document of calculated result scores. This second document is for your use and does not have to be submitted. 

In order to publish the results to the VOT on-line result repository, the ZIP file has to be submitted to the repository maintainers (consult the on-line instructions at the repository website).

Tips and tricks
---------------

* _Parallel execution_ - A full evaluation can be extremely time-consuming. Due to simplicity, the toolkit does not support parallel execution, however, it is possible to execute individual experiments in parallel on multiple computers or on a single multi-core computer with a bit of manual work. The process is described in `internals.md` guide.
* _Clearing results_ - By default the toolkit caches already calculated trials, so that the evaluation can be stopped at any time and resumed later with as little lost data as possible. If you, however, wish to clear the already stored data there are two options. The first one is to disable `track_properties.cache` parameter in your `configuration.m`. The second option is to delete the appropriate directory in the results subdirectory of your working directory. This subdirectory has the same name as your tracker, so make sure that you do not delete the wrong one if you are evaluating multiple trackers.
* _Measuring execution time_ - One of the aspects of trackers performance that is being measured in the evaluation is also execution time. Of course this depends on the hardware, however, some conclusions can also be drawn from these estimates. To make them as reliable as possible it is advisable to perform experiments on a single computer or multiple computers with same the hardware specifications. It is also advisable that the computer is not being used extensively during the evaluation. 

Additional configuration
------------------------

There are several non-essential parameters available in `configuration.m` file.

* `track_properties.debug` sets the debug output option (disabled by default). Using this option it is possible to get additional information regarding the progress of the evaluation, however, its usage is mainly indented for development purposes.
* `track_properties.cache` sets the result caching (enabled by default). By disabling this option all the results are generated every time the evaluation is run instead of preserving results for trials that were already successfully executed.
* `track_properties.pack` sets the result packaging (enabled by default). If enabled, the results of the evaluation are packed into a ZIP archive at the end of the evaluation. This file is ready to be submitted to the VOT on-line result repository.
