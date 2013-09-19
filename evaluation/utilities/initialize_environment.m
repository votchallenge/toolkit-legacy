
global experiment_stack;
global select_configuration;
global select_sequences;
global select_experiment;
global using_trackers;

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

if exist(['stack_', experiment_stack]) ~= 2
    error('Experiment stack %s not available.', experiment_stack);
end;

stack_configuration = str2func(['stack_', experiment_stack]);

experiments = {};

stack_configuration();

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

trackers = cell(length(using_trackers), 1);

print_text('Preparing trackers ...');

for t = 1:length(using_trackers)

    print_indent(1);
    
    print_text('Preparing tracker %s ...', using_trackers{t});

    trackers{t} = create_tracker(using_trackers{t}, ...
        fullfile(results_directory, using_trackers{t}));

    print_indent(-1);
    
end;

if exist('select_experiment', 'var') && ~isempty(select_experiment)
	selected_experiments = unique(select_experiment(select_experiment > 0 & ...
        select_experiment <= length(experiments)));
else
	selected_experiments = 1:length(experiments);
end;
