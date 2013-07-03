
initialize_defaults;

print_text('Running VOT experiments ...');

if exist('configuration') ~= 2
	print_text('Please copy configuration_template.m to configuration.m and configure it.');
	error('Setup file does not exist.');
end;

configuration;

mkpath(track_properties.directory);

sequences_directory = fullfile(track_properties.directory, 'sequences');
results_directory = fullfile(track_properties.directory, 'results');

print_text('Loading sequences ...');

selected_sequences = 'list.txt';
if exist('select_sequences', 'var')
    if ~exist(fullfile(directory, select_sequences), 'file')
        selected_sequences = select_sequences;
    end;
end;

sequences = load_sequences(sequences_directory, selected_sequences);

if isempty(sequences)
	error('No sequences available. Stopping.');
end;

print_text('Preparing tracker %s ...', tracker_identifier);

tracker = create_tracker(tracker_identifier, tracker_command, fullfile(results_directory, tracker_identifier));

