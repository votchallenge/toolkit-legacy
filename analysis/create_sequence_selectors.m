function selectors = create_sequence_selectors(experiment, sequences) %#ok<INUSL>
% create_sequence_selectors Create per-sequence selectors
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
        'aggregate', @(experiment, tracker, sequences) ...
        aggregate_for_sequence(experiment, tracker, sequence), ...
        'practical', @(sequences) get_frame_value(sequence, 'practical'), 'length', @(sequences) count_frames(sequences, i)), ...
        sequences, num2cell(1:length(sequences)), 'UniformOutput', false);        

end

function [aggregated_overlap, aggregated_failures] = aggregate_for_sequence(experiment, tracker, sequence)

    aggregated_overlap = [];
    aggregated_failures = [];


    cache = get_global_variable('cache_selectors', true);
    
    if cache

        result_hash = calculate_results_fingerprint(tracker, experiment, {sequence});

        cache_directory = fullfile(get_global_variable('directory'), 'cache', 'selectors', tracker.identifier, experiment.name);
        mkpath(cache_directory);

        cache_file = fullfile(cache_directory, sprintf('sequence-%s-%s.mat', sequence.name, result_hash));

        if exist(cache_file, 'file')
            load(cache_file);
            if ~isempty(aggregated_overlap) && ~isempty(aggregated_failures)
                return;
            end;
        end;    

    end;
    
    repeat = experiment.parameters.repetitions;
    burnin = experiment.parameters.burnin;

    if ~exist(fullfile(tracker.directory, experiment.name), 'dir')
        print_debug('Warning: Results not available %s', tracker.identifier);
        return;
    end;

    groundtruth = sequence.groundtruth;

    directory = fullfile(tracker.directory, experiment.name, sequence.name);

    accuracy = nan(repeat, sequence.length);
    failures = nan(repeat, 1);

    for j = 1:repeat

        result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, j));

        try 
            trajectory = read_trajectory(result_file);
        catch
            continue;
        end;

        if (size(trajectory, 1) < size(groundtruth, 1))
            print_debug('Warning: Trajectory too short. Expanding with empty frames.');
            trajectory{end+1:length(groundtruth)} = 0;
        end;

        [~, frames] = estimate_accuracy(trajectory, groundtruth, 'burnin', burnin);

        accuracy(j, :) = frames;

        failures(j) = estimate_failures(trajectory, sequence);

    end;

    frames = num2cell(accuracy, 1);
    aggregated_overlap = cellfun(@(frame) nanmean(frame), frames);

    failures(isnan(failures)) = nanmean(failures);
    aggregated_failures = failures';
    
    if cache
        save(cache_file, 'aggregated_overlap', 'aggregated_failures');
    end;
end

function [count, partial] = count_frames(sequences, i)

	count = sequences{i}.length;

    partial = zeros(1, length(sequences));
    
    partial(i) = count;

end


