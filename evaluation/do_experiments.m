
script_directory = fileparts(mfilename('fullpathext'));
include_dirs = cellfun(@(x) fullfile(script_directory,x), {'utilities', 'tracker'},'UniformOutput', false); 
%fullfile(fileparts(mfilename('fullpathext')), 'utilities');

rmpath(include_dirs{:}); addpath(include_dirs{:});

global track_properties;
track_properties = struct('debug', 0, 'cache', 1, 'indent', 0, ...
     'bundle', 'http://box.vicos.si/vot/vot2013.zip', 'repeat', 5);

print_text('Running VOT experiments ...');

track_setup;

if ~exist(track_properties.directory, 'dir')
    mkdir(track_properties.directory);
end;

sequences_directory = fullfile(track_properties.directory, 'sequences');
results_directory = fullfile(track_properties.directory, 'results');

print_text('Loading sequences ...');

sequences = load_sequences(sequences_directory);

if isempty(sequences)
	print_text('No sequences available. Stopping.');
	return;
end;

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

print_text('Packing results ...');

print_indent(1);

resultfile = pack_results(tracker, sequences, {'experiment_1'});

print_indent(-1);

print_text('Result pack stored to "%s"', resultfile);

print_text('Done.');
