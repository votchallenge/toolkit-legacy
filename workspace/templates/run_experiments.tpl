% This script can be used to execute the experiments for a single tracker
% You can copy and modify it to create another experiment launcher

addpath('{{toolkit}}');
toolkit_path;

[sequences, experiments] = workspace_load();

tracker = create_tracker('{{tracker}}');

workspace_evaluate(tracker, sequences, experiments);

