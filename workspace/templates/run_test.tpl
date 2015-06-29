% This script can be used to test the integration of a tracker to the
% framework.

addpath('{{toolkit}}');
toolkit_path;

[sequences, experiments] = workspace_load();

tracker = create_tracker('{{tracker}}');

workspace_test(tracker, sequences);

