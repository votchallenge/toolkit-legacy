% This script can be used to interactively inspect the results

addpath('{{toolkit}}'); toolkit_path; % Make sure that VOT toolkit is in the path

[sequences, experiments] = workspace_load();

trackers = tracker_load('{{tracker}}');

workspace_browse(trackers, sequences, experiments);

