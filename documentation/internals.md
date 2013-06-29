Details about the toolkit
=========================

This document contains a detailed description of the several internal mechanisms of the evaluation toolkit.

Working directory
-----------------

The working directory automatically populated with several subdirectories:

* `sequences/` - This subdirectory contains sequence data. By default the testing sequence dataset will be automatically downloaded the first time the evaluation starts in a specific working directory. Alternatively you can download the entire dataset manually and extract it to this directory. Each sequence is contained in a separate directory with the following structure:
	- `<sequence name>/` - A directory that contains a sequence.
		* `groundtruth.txt` - Annotations file.
   		* `00000001.jpg`
   		* `00000002.jpg`
   		* `00000003.jpg`
   		* `...`
* `results/` - Results of the tracking for multiple trackers.
	- `<tracker identifier>/` - Results for a specific tracker.
		* `<experiment name>/` - Results for a specific experiment.
   		* `<sequence name>/` - Results for a sequence
   			* `<sequence name>_<iteration>.txt` - Result data for iteration.
* `cache/` - Cached data that can be deleted and can be generated on demand. An example of this are gray-scale sequences that are generated from their color originals on demand.

Evaluation execution and parallelism
------------------------------------

By default the entire evaluation is performed sequentially as described by the following pseudo-code:

    tracker t
    for experiment e:
        for sequence s:
            repeat r times (if tracker is stochastic):
                perform trial for (t, s)
            end
        end
    end

Each trial contains one or more executions of the tracker. The idea is that if the tracker fails during tracking the execution is repeated from the point of the failure (plus additional offset frames). Tracker failure is determined using the overlap criterion with threshold 0 (the tracker fails if the overlap between the ground-truth and the predicted region is 0).

In the case of stochastic trackers, each sequence is evaluated multiple times. If the tracker produces identical trajectories two times in a row, the tracker is considered deterministic and further iterations are omitted. It is therefore important that the stochastic nature of a tracker is appropriately addressed (proper random seed initialization).

Because of this methodology, the entire execution time can be quite long. If we assume that we have a stochastic tracker that runs less than real-time. Let’s assume that it takes 0.5 second per frame. The average length of a sequence is 350 frames. The tracker performs 15 trials on each sequence, and there are 15 sequences in the dataset. We pessimistically assume that a tracker fails uniformly 8 times throughout the sequence, which approximately amounts to equivalent of 5 re-runs over entire sequence. We get the following rule-of-thumb estimate of the time required to perform the experiment is more than two days for a single experiment. The entire evaluation contains three experiments which results in roughly 7 days of execution.

To speed up the execution, the evaluation can be parallelized. Due to simplicity, the toolkit does not support parallel execution explicitly, however, it is possible to execute individual experiments in parallel on multiple computers or on a single multi-core computer with a bit of manual work, thus reducing the evaluation time back to 2-3 days.

To separate execution of the evaluation on a single multi-core computer simply run three instances of the interpreter (Matlab or Octave). Disable result package creation (using `track_properties.pack`). In each of the interactive shells set a variable `selected_experiment` to one of the values from 1 to 3. Then execute the evaluation by calling `do_experiments`. After all three experiments are done, re-enable result package creation, clear the variables, and call `do_experiments` again in one of the interactive shells.

To separate execution on multiple computers more manual work is needed. On each computer configure the toolkit, run an interpreter (Matlab or Octave), and proceed in similar manner than with the multi-core computer. Note that by default sequences will be downloaded on each computer, which can be avoided by copying the initialized workspace from one computer to the rest. The results have to be manually merged on a single computer by copying the result data for each experiment in the `results` directory. Only then re-enable result package creation, clear the variables, and call `do_experiments` again.

Results bundle
--------------

When the evaluation is complete the data is bundled in a zip file that can be used to submit your results to the VOT Challenge website. The zip file contains raw tracking results from the `results` directory together with some tracker and platform meta-data. The structure of the data is the same as in the `results` directory.


