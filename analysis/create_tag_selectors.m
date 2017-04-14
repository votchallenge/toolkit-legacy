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
        'aggregate', @(experiment, tracker, sequences) ...
        aggregate_for_tag(experiment, tracker, sequences, tag), ...
        'practical', @(sequences) practical_for_tag(sequences, tag), ...
        'length', @(sequences) count_for_tag(sequences, tag)), ...
        tags, 'UniformOutput', false);

end

function [aggregated_overlap, aggregated_failures] = aggregate_for_tag(experiment, tracker, sequences, tag)

    aggregated_overlap = [];
    aggregated_failures = [];

    cache = get_global_variable('cache_selectors', true);

    if cache
        result_hash = calculate_results_fingerprint(tracker, experiment, sequences);

        cache_directory = fullfile(get_global_variable('directory'), 'cache', 'selectors', tracker.identifier, experiment.name);
        mkpath(cache_directory);

        cache_file = fullfile(cache_directory, sprintf('tag-%s-%s.mat', tag, result_hash));

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

    for s = 1:length(sequences)

        filter = sequence_query_tag(sequences{s}, tag);

        if isempty(filter) || ~any(filter)
            continue;
        end;

        groundtruth = sequences{s}.groundtruth;

        directory = fullfile(tracker.directory, experiment.name, sequences{s}.name);

        accuracy = nan(repeat, length(filter));
        failures = nan(repeat, 1);

        for j = 1:repeat

            result_file = fullfile(directory, sprintf('%s_%03d.txt', sequences{s}.name, j));

            try
                trajectory = read_trajectory(result_file);
            catch
                continue;
            end;

            if (size(trajectory, 1) < size(groundtruth, 1))
                print_debug('Warning: Trajectory too short. Expanding with empty frames.');
                trajectory(end+1:length(groundtruth)) = {0};
            end;

            [~, frames] = estimate_accuracy(trajectory(filter), groundtruth(filter), 'burnin', burnin);

            accuracy(j, :) = frames;

            failures(j) = estimate_failures(trajectory(filter), sequences{s});

        end;

        frames = num2cell(accuracy, 1);
        sequence_overlaps = cellfun(@(frame) nanmean(frame), frames);

        failures(isnan(failures)) = nanmean(failures);
        sequence_failures = failures';

        if ~isempty(sequence_overlaps)
            aggregated_overlap = [aggregated_overlap, sequence_overlaps]; %#ok<AGROW>
        end;

        if ~isempty(sequence_failures)
            aggregated_failures = [aggregated_failures; sequence_failures]; %#ok<AGROW>
        end;

    end

    if cache
        save(cache_file, 'aggregated_overlap', 'aggregated_failures');
    end;

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

