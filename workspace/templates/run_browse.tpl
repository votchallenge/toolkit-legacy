% This script can be used to interactively inspect the results

addpath('{{toolkit}}');
toolkit_path;

[sequences, experiments] = workspace_load();

trackers = create_trackers('{{tracker}}');

workspace_browse(trackers, sequences, experiments);

