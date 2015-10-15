% This script can be used to visualize VOT results in form of images

addpath('{{toolkit}}'); toolkit_path; % Make sure that VOT toolkit is in the path

[sequences, experiments] = workspace_load();

% tracker list may contain multiple tracker for comparison of multiple methods
trackers = tracker_list('{{tracker}}');

workspace_visualize(trackers, sequences, experiments);
