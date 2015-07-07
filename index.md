VOT toolkit documentation
=========================

This is the official documentation for the [Visual Object Tracking (VOT) challenge](http://votchallenge.net/) toolkit. The toolkit is a set of
Matlab (Octave compatible) scripts that estimate the performance of visual object trackers.

The official code repository is available on [Github](https://github.com/vicoslab/vot-toolkit/). You can also
subscribe to the VOT [mailing list](https://service.ait.ac.at/mailman/listinfo/votchallenge) to receive news about challenges and important software updates.

Platform support
----------------

The toolkit is written in Matlab language with a strong emphasis on Octave compatibility as well as support for multiple versions of Matlab (at the moment it was tested with versions from 2011 to 2015).

The code should work on Windows, Linux and OSX, however, it is hard to verify this on all versions and system configurations. If you therefore find that there are some issues on your computer setup, submit a bug report at [Github](https://github.com/vicoslab/vot-toolkit/issues/new) as soon as possible.

Inquiries, Question and Comments
--------------------------------

If you have any further inquiries, question, or comments, please use the official [support forum](https://groups.google.com/forum/?hl=en#!forum/votchallenge-help). If you would like to file a bug report or a feature request, use the [Github issue tracker](https://github.com/vicoslab/vot-toolkit/issues).

Terminology
-----------

For better understanding, here are some definitions of important terms that are used in the documentation:

* _Workspace_ - An directory that contains results for a single stack of experiments and your working scripts. It should not be the same directory that also contains the toolkit. 
* _Tracker_ - An executable or a script containing a tracking algorithm that is evaluated. 
* _Sequence_ - A single sequence of images with manually annotated ground-truth positions of the object used for evaluation.
* _Annotation_ - Manual or automatic description of visual position of the object.
* _Trajectory_ - A sequence of annotations that describes the motion of the object in the sequence. In the toolkit it is saved to a file in a text format.
* _Tracker run_ - A single execution of a tracker on an entire sequence or its subset.
* _Trial_ - If a tracker fails during tracking it is reinitialized after the first point of failure.
* _Repetition_ - To properly address the potential stochastic nature of the algorithm, several trials are performed on each sequence.
* _Experiment_ - Evaluation of a tracker on a set of sequences in specific conditions. Specific experiment may change the original sequences to simulate some specific kind of circumstances (e.g. image noise, initialization error).
* _Evaluation_ - Performing a set of experiments on a specific tracker.
* _Region overlap_ - Overlap distance between two regions.

Modules
-------

The toolkit contains of several interdependent modules:

-   [Workspace](workspace/index.md)
-   [Tracker](tracker/index.md)
-   [Sequence](sequence/index.md)
-   [Analysis](analysis/index.md)
-   [Report](report/index.md)
-   [Utilities](utilities/index.md)

