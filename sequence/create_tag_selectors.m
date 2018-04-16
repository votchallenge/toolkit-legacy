function selectors = create_tag_selectors(experiment, sequences, tags) %#ok<INUSL>
% create_tag_selectors Create per-tag selector
%
% Create a set of selectors for a set of tags upon a set of sequences.
%
% Input:
% - experiment (structure): A valid experiment descriptor.
% - sequences (cell): A cell array of valid sequence descriptors.
% - tags (cell): A cell array of tag names.
%
% Output:
% - selectors (cell): A cell array of selector structures, one for each tag.
%

    selectors = cellfun(@(tag) struct('name', sprintf('tag_%s', tag), ...
        'title', tag, ...
        'aggregate_groundtruth', @(experiment, sequences) groundtruth_for_tag(experiment, sequences, tag), ...
        'aggregate_results', @(experiment, tracker, sequences) results_for_tag(experiment, tracker, sequences, tag), ...
        'aggregate_results_values', @(experiment, tracker, sequences, value) ...
        result_values_for_tag(experiment, tracker, sequences, tag, value), ...
        'practical', @(sequences) practical_for_tag(sequences, tag), ...
        'length', @(sequences) count_for_tag(sequences, tag)), ...
        tags, 'UniformOutput', false);

end


function [groundtruth] = groundtruth_for_tag(experiment, sequences, tag)

    groundtruth = cell(numel(sequences), 1);

    for s = 1:length(sequences)

        filter = sequence_query_tag(sequences{s}, tag);

        if isempty(filter) || ~any(filter)
            continue;
        end;

        groundtruth{s} = sequences{s}.groundtruth(filter);

    end

end

function [results] = results_for_tag(experiment, tracker, sequences, tag)

    repeat = experiment.parameters.repetitions;

    results = cell(numel(sequences), repeat);

    if ~exist(fullfile(tracker.directory, experiment.name), 'dir')
        print_debug('Warning: Results not available %s', tracker.identifier);
        return;
    end;

    for s = 1:length(sequences)

        filter = sequence_query_tag(sequences{s}, tag);

        if isempty(filter) || ~any(filter)
            continue;
        end;

        groundtruth = sequences{s}.groundtruth;

        directory = fullfile(tracker.directory, experiment.name, sequences{s}.name);
        
        for j = 1:repeat

            result_file = fullfile(directory, sprintf('%s_%03d.txt', sequences{s}.name, j));

            try
                trajectory = read_trajectory(result_file);
                
                if (size(results{s, j}, 1) < size(groundtruth, 1))
                    %print_debug('Warning: Trajectory too short. Expanding with empty frames.');
                    trajectory(end+1:length(groundtruth)) = {0};
                end;
                
                results{s, j} = trajectory(filter);
                
            catch
                continue;
            end;

        end;

    end
    
end

function [results] = result_values_for_tag(experiment, tracker, sequences, tag, value)

    repeat = experiment.parameters.repetitions;

    results = cell(numel(sequences), repeat);

    if ~exist(fullfile(tracker.directory, experiment.name), 'dir')
        print_debug('Warning: Results not available %s', tracker.identifier);
        return;
    end;

    for s = 1:length(sequences)

        filter = sequence_query_tag(sequences{s}, tag);

        if isempty(filter) || ~any(filter)
            continue;
        end;

        groundtruth = sequences{s}.groundtruth;

        directory = fullfile(tracker.directory, experiment.name, sequences{s}.name);
        
        for j = 1:repeat

            result_file = fullfile(directory, sprintf('%s_%03d.txt', sequences{s}.name, j));

            try
                trajectory = read_trajectory(result_file);
                
                if (size(results{s, j}, 1) < size(groundtruth, 1))
                    %print_debug('Warning: Trajectory too short. Expanding with empty frames.');
                    trajectory(end+1:length(groundtruth)) = {0};
                end;
                
                results{s, j} = trajectory(filter);
                
            catch
                continue;
            end;

        end;

    end
    
end

function [count, partial] = count_for_tag(sequences, tag)

	count = 0;

    partial = zeros(1, length(sequences));

    for s = 1:length(sequences)

        filter = sequence_query_tag(sequences{s}, tag);

        if isempty(filter)
            continue;
        end;

		count = count + numel(filter);

        partial(s) = numel(filter);

    end
end


function practical = practical_for_tag(sequences, tag)

    practical = [];

    for s = 1:length(sequences)

        filter = sequence_query_tag(sequences{s}, tag);

        if isempty(filter)
            continue;
        end;

        p = get_frame_value(sequences{s}, 'practical', filter);

        if ~isempty(p)
            practical = [practical; p]; %#ok<AGROW>
        end;

    end;

end

