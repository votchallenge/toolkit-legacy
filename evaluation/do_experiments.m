
script_directory = fileparts(mfilename('fullpath'));
include_dirs = cellfun(@(x) fullfile(script_directory,x), {'', 'utilities', 'tracker', 'sequence', 'measures', 'experiment'}, 'UniformOutput', false); 
rmpath(include_dirs{:}); addpath(include_dirs{:});

global track_properties;
track_properties = struct('debug', 0, 'cache', 1, 'indent', 0, 'pack', 1, ...
     'bundle', 'http://box.vicos.si/vot/vot2013.zip', 'repeat', 5);

print_text('Running VOT experiments ...');

if exist('configuration') ~= 2
	print_text('Setup file does not exist.');
	print_text('Please copy configuration_template.m to configuration.m and configure it.');
	return;
end;

configuration;

mkpath(track_properties.directory);

sequences_directory = fullfile(track_properties.directory, 'sequences');
results_directory = fullfile(track_properties.directory, 'results');

print_text('Loading sequences ...');

sequences = load_sequences(sequences_directory);

if isempty(sequences)
	print_text('No sequences available. Stopping.');
	return;
end;

print_text('Preparing tracker %s ...', tracker_identifier);

tracker = create_tracker(tracker_identifier, tracker_command, fullfile(results_directory, tracker_identifier));

experiments = {'baseline', 'region_noise', 'skipping'};

for e = 1:length(experiments)

    if exist(['experiment_', experiments{e}]) ~= 2
        continue;
    end;

    experiment_function = str2func(['experiment_', experiments{e}]);

    print_text('Running Experiment "%s" ...', experiments{e});

    print_indent(1);

    experiment_directory = fullfile(tracker.directory, experiments{e});

    experiment_function(tracker, sequences, experiment_directory)

    scores = calculate_ar_score(tracker, sequences, experiment_directory);

    print_text('Experiment complete. Outputting final A-R scores:');

    print_indent(1);

    for i = 1:length(sequences)
        print_text('Sequence "%s" - Accuracy: %.3f, Reliability: %.3f', sequences{i}.name, scores(i, 1), scores(i, 2));
    end;

    print_indent(-2);

end;

if track_properties.pack

    print_text('Packing results ...');

    print_indent(1);

    resultfile = pack_results(tracker, sequences, experiments);

    print_indent(-1);

    print_text('Result pack stored to "%s"', resultfile);

else

    print_debug('Omitting result packaging.');

end;

print_text('Done.');
