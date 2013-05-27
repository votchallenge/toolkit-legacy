
util_dir = fullfile(fileparts(mfilename('fullpathext')), 'utilities');
rmpath(util_dir); addpath(util_dir);

global track_properties;
track_properties = struct('debug', 0, 'cache', 1, 'indent', 0, ...
     'bundle', 'http://box.vicos.si/vot/bundle2013.zip', 'repeat', 5);

print_text('Running VOT experiments ...');

track_setup;

if ~exist(track_properties.directory, 'dir')
    mkdir(track_properties.directory);
end;

sequences_directory = fullfile(track_properties.directory, 'sequences');
results_directory = fullfile(track_properties.directory, 'results');

print_text('Loading sequences ...');

sequences = load_sequences(sequences_directory);

print_text('Preparing tracker %s ...', tracker_identifier);

tracker = track_create_tracker(tracker_identifier, tracker_command, fullfile(results_directory, tracker_identifier));

print_text('Running Experiment 1 ...');

print_indent(1);

experiment_directory = fullfile(tracker.directory, 'experiment_1');

for i = 1:length(sequences)
    print_text('Sequence "%s" (%d/%d)', sequences{i}.name, i, length(sequences));
    track_repeat(tracker, sequences{i}, track_properties.repeat, fullfile(experiment_directory, sequences{i}.name));
end;

print_indent(-1);

print_text('Done.');
