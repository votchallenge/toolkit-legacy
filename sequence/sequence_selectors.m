function selectors = sequence_selectors(experiment, sequences) %#ok<INUSL>
% sequence_selectors Create per-sequence selectors
%
% Creates a set of selectors for a given set of sequences where each selector corresponds to a single selector.
%
% Input:
% - experiment (structure): A valid experiment descriptor.
% - sequences (cell): A cell array of valid sequence descriptors.
%
% Output:
% - selectors (cell): A cell array of selector structures, one for each sequence.
%

    selectors = cellfun(@(sequence, i) struct('name', sprintf('sequence_%s', sequence.name), ...
        'title', sequence.name, ...
        'groundtruth', @(sequences) groundtruth_for_sequence(sequences, i), ...
        'groundtruth_values', @(sequences, value) groundtruth_value_for_sequence(sequences, i, value), ...
        'results', @(experiment, tracker, sequences) results_for_sequence(experiment, tracker, sequences, i), ...
        'results_values', @(experiment, tracker, sequences, value) ...
        result_values_for_sequence(experiment, tracker, sequences, i, value), ...
        'length', @(sequences) count_frames(sequences, i)), ...
        sequences, num2cell(1:length(sequences)), 'UniformOutput', false);

end

function groundtruth = groundtruth_for_sequence(sequences, i)

    groundtruth = cell(numel(sequences), 1);

    groundtruth{i} = sequences{i}.groundtruth;

end

function groundtruth = groundtruth_value_for_sequence(sequences, i, value)

    groundtruth = cell(numel(sequences), 1);

    groundtruth{i} = sequence_get_frame_value(sequences{i}, value);

end

function results = results_for_sequence(experiment, tracker, sequences, i)

    repeat = experiment.parameters.repetitions;

    results = cell(numel(sequences), repeat);

    if ~exist(fullfile(tracker.directory, experiment.name), 'dir')
        print_debug('Warning: Results not available %s', tracker.identifier);
        return;
    end;

    groundtruth = sequences{i}.groundtruth;

    directory = fullfile(tracker.directory, experiment.name, sequences{i}.name);

    for j = 1:repeat

        result_file = fullfile(directory, sprintf('%s_%03d.txt', sequences{i}.name, j));

        try
            trajectory = read_trajectory(result_file);
        catch
            continue;
        end;

        if (size(trajectory, 1) < size(groundtruth, 1))
            print_debug('Warning: Trajectory too short. Expanding with empty frames.');
            trajectory(end+1:length(groundtruth)) = {0};
        end;

        results{i, j} = trajectory;

    end;

end

function values = result_values_for_sequence(experiment, tracker, sequences, s, value)

    repeat = experiment.parameters.repetitions;

    values = cell(numel(sequences), repeat);

    if ~exist(fullfile(tracker.directory, experiment.name), 'dir')
        print_debug('Warning: Results not available %s', tracker.identifier);
        return;
    end;

    directory = fullfile(tracker.directory, experiment.name, sequences{s}.name);

    for j = 1:repeat

        values_file = fullfile(directory, sprintf('%s_%03d_%s.value', sequences{s}.name, j, value));

        data = nan(sequences{s}.length, 1);

        i = 0;

        try
            fp = fopen(values_file, 'r');

            while true
                 line = fgets(fp);

                 if line == -1
                     break;
                 end

                 [v, numeric] = str2num(line(1:end-1)); %#ok<ST2NM>

                 if ~numeric
                    v = line(1:end-1);
                 end

                 i = i + 1;

                 if isempty(v)
                     continue;
                 end;

                 data(i) = v;

            end;

            fclose(fp);

            values{s, j} = data;

        catch
            continue;
        end;

    end;

end

function [count, partial] = count_frames(sequences, i)

	count = sequences{i}.length;

    partial = zeros(1, length(sequences));

    partial(i) = count;

end


