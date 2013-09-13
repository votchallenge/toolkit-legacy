
global select_configuration;
global experiment_stack;
global select_sequences;
global select_experiment;

initialize_defaults;

print_text('Running VOT experiments ...');

if exist('select_configuration', 'var')
	environment_configuration = str2func(select_configuration);
    environment_configuration();
else
    if exist('configuration') ~= 2
        print_text('Please copy configuration_template.m to configuration.m in your workspace and edit it.');
        error('Setup file does not exist.');
    else
        configuration();
    end; 
end;

mkpath(track_properties.directory);

sequences_directory = fullfile(track_properties.directory, 'sequences');
results_directory = fullfile(track_properties.directory, 'results');

print_text('Loading sequences ...');

selected_sequences = 'list.txt';
if exist('select_sequences', 'var') && ~isempty(select_sequences)
    if exist(fullfile(sequences_directory, select_sequences), 'file')
        selected_sequences = select_sequences;
    end;
end;

sequences = load_sequences(sequences_directory, selected_sequences);

if isempty(sequences)
	error('No sequences available. Stopping.');
end;

print_text('Preparing tracker %s ...', tracker_identifier);

tracker = create_tracker(tracker_identifier, tracker_command, ...
        fullfile(results_directory, tracker_identifier), 'linkpath', tracker_linkpath);

if exist(['stack_', experiment_stack]) ~= 2
    error('Experiment stack %s not available.', experiment_stack);
end;

stack_configuration = str2func(['stack_', experiment_stack]);

experiments = {};

stack_configuration();

if exist('select_experiment', 'var') && ~isempty(select_experiment)
	selected_experiments = unique(select_experiment(select_experiment > 0 & ...
        select_experiment <= length(experiments)));
else
	selected_experiments = 1:length(experiments);
end;
