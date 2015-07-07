Workspace module
================

This module contains functions that are used to initialize, load and use a workspace. A workspace is a dedicated
directory, separate from the toolkit directory, where experiment-specific results are stored. The directory contains
several special subdirectories that contain sequence data, per-tracker raw results, report documents, and cached data.

About workspace
---------------

The workspace is automatically populated with several subdirectories:

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

Evaluation process
------------------

By default the entire evaluation is performed sequentially as described by the following pseudo-code:

    tracker t
    for experiment e:
        for sequence s:
            repeat r times (if tracker is stochastic):
                perform trial for (t, s)
            end
        end
    end

Each trial contains one or more executions of the tracker. The idea is that if the tracker fails during tracking the execution (the failure criterion can be experiment dependent) it is repeated from the point of the failure (plus additional offset frames if specified).

In the case of stochastic trackers, each sequence is evaluated multiple times. If the tracker produces identical trajectories two times in a row, the tracker is considered deterministic and further iterations are omitted. It is therefore important that the stochastic nature of a tracker is appropriately addressed (proper random seed initialization).

Because of the thorough methodology, the entire execution can take quite some time. The function [workspace_test](workspace_test.m) provides an option for estimating the processing time for the entire evaluation based on a single run on one sequence.

Module functions
----------------

-   [workspace_create](workspace_create.m) - Initialize a new VOT workspace
-   [workspace_browse](workspace_browse.m) - Browse and visualize the results in the workspace
-   [workspace_evaluate](workspace_evaluate.m) - Perform evaluation of a set of trackers
-   [workspace_load](workspace_load.m) - Initializes the current workspace 
-   [workspace_submit](workspace_submit.m) - Generates a valid result archive
-   [workspace_test](workspace_test.m) - Tests the integration of a tracker into the toolkit

### Utility

-   [get_global_variable](get_global_variable.m) - Get a workspace global variable
-   [set_global_variable](set_global_variable.m) - Set a workspace global variable
-   [print_indent](print_indent.m) - Modify the indent of the output
-   [print_debug](print_debug.m) - Prints formatted debug text
-   [print_text](print_text.m) - Prints formatted text
