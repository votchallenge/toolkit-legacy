function workspace_browse(trackers, sequences, experiments, varargin)
% workspace_browse Browse and visualize the results in the workspace
%
% The function provides an interactive interface for browsing results in
% the workspace.
%
% Input:
% - trackers (cell or structure): Array of tracker structures.
% - sequences (cell or structure): Array of sequence structures.
% - experiments (cell or structure): Array of experiment structures.
%

selected_tracker = [];
selected_experiment = [];
selected_sequence = [];

if ~iscell(trackers)
    trackers = {trackers};
end;

if ~iscell(sequences)
    sequences = {sequences};
end;

if ~iscell(experiments)
    experiments = {experiments};
end;

while 1

    if isempty(selected_experiment)

        if length(experiments) == 1
            selected_experiment = 1;

            continue;
        else

            print_text('Choose experiment:');
            print_indent(1);

            for i = 1:length(experiments)
                print_text('%d - "%s"', i, experiments{i}.name);
            end;

            print_text('b - Back');
            print_text('e - Exit');
            print_indent(-1);


            option = input('Select experiment: ', 's');

            switch option
                case {'q', 'e'}
                    return;
                case 'b'
                    break;
                otherwise
                    selected_experiment = int32(str2double(option));

                    if isempty(selected_experiment) || selected_experiment < 1 || selected_experiment > length(experiments)
                        selected_experiment = [];
                    end;

                    continue;
            end;
        end;
    end;

    if isempty(selected_sequence)

        if length(sequences) == 1
            selected_sequence = 1;

            continue;
        else

            print_text('Choose sequence:');
            print_indent(1);

            for i = 1:length(sequences)
                print_text('%d - "%s"', i, sequences{i}.name);
            end;

            print_text('b - Back');
            print_text('e - Exit');
            print_indent(-1);

            option = input('Select sequence: ', 's');
            switch option
                case {'q', 'e'}
                    return;
                case 'b'
                    selected_experiment = [];
                    selected_sequence = [];
                    continue;
                otherwise

                    selected_sequence = int32(str2double(option));

                    if isempty(selected_sequence) || selected_sequence < 1 || selected_sequence > length(sequences)
                        selected_sequence = [];
                    end;

                    continue;
            end;
        end;

    end;


    if isempty(selected_tracker)

        if length(trackers) == 1
            selected_tracker = 1;

            continue;
        else

            print_text('Choose tracker:');
            print_indent(1);

            for i = 1:length(trackers)
                print_text('%d - "%s"', i, trackers{i}.identifier);
            end;

            print_text('b - Back');
            print_text('e - Exit');
            print_indent(-1);


            option = input('Selected tracker: ', 's');

            switch option
                case {'q', 'e'}
                    return;
                case 'b'
                    selected_sequence = [];
                    selected_tracker = [];
                    continue;
                otherwise

                    selected_tracker = int32(str2double(option));

                    if isempty(selected_tracker) || selected_tracker < 1 || selected_tracker > length(trackers)
                        selected_tracker = [];
                    end;

                    continue;

            end;
        end;
    end;

    tracker = trackers{selected_tracker};
    experiment = experiments{selected_experiment};

    sequence = convert_sequences(sequences(selected_sequence), experiment.converter);
	sequence = sequence{1};

    switch experiment.type
        case {'supervised', 'unsupervised', 'chunked'}
            visualize_default(experiment, tracker, sequence);
        otherwise
            experiment_function = str2func(['experiment_', experiment.type, '_visualize']);
        	experiment_function(experiment, tracker, sequence);
    end

    selected_tracker = [];
    if length(trackers) == 1
        selected_sequence = [];
    end;

    if length(sequences) == 1
        selected_experiment = [];
    end;

end;

end

function visualize_default(experiment, tracker, sequence)

    experiment_directory = fullfile(tracker.directory, experiment.name);

    sequence_directory = fullfile(experiment_directory, sequence.name);

    trajectories = {};

    for i = 1:experiment.parameters.repetitions;

        tfile = fullfile(sequence_directory, ...
            sprintf('%s_%03d.txt', sequence.name, i));

        if exist(tfile, 'file')
            trajectories{end+1} = read_trajectory(tfile); %#ok<AGROW>
        end;

    end;

    if isempty(trajectories)
        print_text('No results found for sequence');
        return;
    end;

    sequence_visualize(sequence, trajectories{:});

end



