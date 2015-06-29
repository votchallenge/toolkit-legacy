% This script can be used to pack the results and submit them to a challenge.

addpath('{{toolkit}}');
toolkit_path;

[sequences, experiments] = workspace_load();

tracker = create_tracker('{{tracker}}');

workspace_submit(tracker, sequences, experiments);

