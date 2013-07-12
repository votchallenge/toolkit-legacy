Details about the toolkit
=========================

This document contains a detailed description of the several internal mechanisms of the evaluation toolkit.

Working directory
-----------------

The working directory is automatically populated with several subdirectories:

* `sequences/` - This subdirectory contains sequence data. By default the testing sequence dataset will be automatically downloaded the first time the evaluation starts in a specific working directory. Alternatively you can download the entire dataset manually and extract it to this directory. Each sequence is contained in a separate directory with the following structure:
	- `<sequence name>/` - A directory that contains a sequence.
		* `groundtruth.txt` - Annotations file.
   		* `00000001.jpg`
   		* `00000002.jpg`
   		* `00000003.jpg`
   		* `...`
* `results/` - Results of the tracking for multiple trackers.
	- `<tracker identifier>/` - All results for a specific tracker.
		* `<experiment name>/` - All results for a specific experiment.
   		* `<sequence name>/` - All results for a sequence.
   			* `<sequence name>_<iteration>.txt` - Result data for iteration.
* `cache/` - Cached data that can be deleted and can be generated on demand. An example of this are gray-scale sequences that are generated from their color originals on demand.

Evaluation execution
--------------------

By default the entire evaluation is performed sequentially as described by the following pseudo-code:

    tracker t
    for experiment e:
        for sequence s:
            repeat r times (if tracker is stochastic):
                perform trial for (t, s)
            end
        end
    end

Each trial contains one or more executions of the tracker. The idea is that if the tracker fails during tracking the execution is repeated from the point of the failure (plus additional offset frames). A tracker failure is declared on the first frame where there is no overlap between the ground-truth and the predicted region (the tracker fails if the overlap between the ground-truth and the predicted region is 0).

In the case of stochastic trackers, each sequence is evaluated multiple times. If the tracker produces identical trajectories two times in a row, the tracker is considered deterministic and further iterations are omitted. It is therefore important that the stochastic nature of a tracker is appropriately addressed (proper random seed initialization).

Because of the thorough methodology, the entire execution time can be quite long. Let’s assume that we have a stochastic tracker that requires 0.5 seconds to process a single frame. The average length of a sequence is 350 frames. The tracker performs 15 trials on each sequence, and there are 16 sequences in the dataset. We pessimistically assume that a tracker fails uniformly 8 times throughout the sequence, which approximately amounts to equivalent of 5 re-runs over entire sequence. Based on these assumptions a rule-of-thumb estimate of the time required to perform a single experiment is more than two days. The entire evaluation contains three experiments which results in roughly 7 days. The function `do_test()` provides an option for estimating the processing time for the entire evaluation based on a single run on one sequence.

Parallelism
-----------

To speed up the execution, the evaluation can be parallelized. Due to simplicity, the toolkit does not support parallel execution explicitly, however, it is possible to execute individual experiments in parallel on multiple computers or on a single multi-core computer with a bit of manual work, thus reducing the evaluation time back to 2-3 days. The other, more complicated option is to separate the execution by sequence dataset partitioning.

**Parallelize by experiment**: To separate execution of the evaluation on a single multi-core computer simply run three instances of the interpreter (Matlab or Octave). Disable result package creation (using `track_properties.pack`). In each of the interactive shells set a variable `selected_experiment` to one of the values from 1 to 3. Then execute the evaluation by calling `do_experiments`. After all three experiments are done, re-enable result package creation, clear the variables, and call `do_experiments` again in one of the interactive shells.

To separate execution on multiple computers more manual work is needed. On each computer configure the toolkit, run an interpreter (Matlab or Octave), and proceed in similar manner than with the multi-core computer. Note that by default sequences will be downloaded on each computer, which can be avoided by copying the initialized workspace from one computer to the rest. The results have to be manually merged on a single computer by copying the result data for each experiment in the `results` directory. Only then re-enable result package creation, clear the variables, and call `do_experiments` again.

**Parallelize by dataset partitioning**: Another option to speed up the evaluation is to form dataset partitioning. This option requires more manual work, but also offers better options of parallelization.

By default the toolkit assembles a list of sequences by reading the `list.txt` file in the `sequences` directory. This file contains a list of all the sequences in the evaluation. To split the execution into multiple parts prepare files `list1.txt`, `list2.txt` ... `listN.txt` in the `sequences` directory and copy appropriate subsets of sequences from the `list.txt` into each of them. Then open N interpreters (one one or more computers) and set the variable `selected_sequences` to `list<I>.txt` where `I` = 1 ... N on each of the environments before running the `do_experiments` function. 

Other instructions (disabling package creation and result merging for multi-computer setup) are the same as with the parallelization by experiment.

Trajectory format
-----------------

The tracker has to output a single bounding box per frame. The final output of the tracker (the final combined bounding-box trajectory) is encoded as a comma-separated list of four values per frame:

    <left_1>,<top_1>,<width_1>,<height_1>
    <left_2>,<top_2>,<width_2>,<height_2>
    <left_3>,<top_3>,<width_3>,<height_3>
    <left_4>,<top_4>,<width_4>,<height_4>
    ...

This stored sequence describes the entire tracking trial process with failures and re-initializations encoded between regular frames in a special format. All irregular frame states have `left`, `top` and `width` values set to `NaN`. The `height` negative values define the type of the special frame:

* Initialization of the tracker: `height = -1`.
* Failure of the tracker: `height = -2`.
* Undefined state due to frame skipping: `height = 0`.

Results bundle
--------------

When the evaluation is complete the data is bundled in a zip file that can be used to submit your results to the VOT Challenge website. The zip file contains raw tracking results from the `results` directory together with some tracker and platform meta-data. The structure of the data is the same as in the `results` directory.


