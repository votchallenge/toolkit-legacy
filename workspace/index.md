Workspace module
================

This module contains functions that are used to initialize, load and use a workspace. A workspace is a dedicated
directory, separate from the toolkit directory, where experiment-specific results are stored. The directory contains
several special subdirectories that contain sequence data, per-tracker raw results, report documents, and cached data.

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
