
% This file serves only as a basic test for some functionality and has to be removed soon.

util_dir = fullfile(pwd, 'utilities');
rmpath(util_dir); addpath(util_dir);

test_sequence = '<TODO: set path to sequence directory>';

track_dummy = fullfile(pwd, '..', 'examples', 'c', 'track_dummy');

%For MATLAB:
%track_dummy = 'MS_Tracker_Example'

tracker = track_create_tracker(track_dummy);
sequence = track_create_sequence(test_sequence);

[trajectory, time] = track_trial(tracker, sequence, 1);

time
