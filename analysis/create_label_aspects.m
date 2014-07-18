function aspects = create_label_aspects(experiment, tracker, sequences, labels) %#ok<INUSL>

    aspects = cellfun(@(label) struct('name', sprintf('label_%s', label), ...
        'title', label, ...
        'aggregate', @(experiment, tracker, sequences) ...
        aggregate_for_label(experiment, tracker, sequences, label), ...
        'practical', @(sequences) practical_for_label(sequences, label)), ...
        labels, 'UniformOutput', false);

end

function [A, R] = aggregate_for_label(experiment, tracker, sequences, label)

    A = [];
    R = [];

    repeat = get_global_variable('repeat', 1);
    burnin = get_global_variable('burnin', 0);    

    if ~exist(fullfile(tracker.directory, experiment.name), 'dir')
        print_debug('Warning: Results not available %s', tracker.identifier);
        return;
    end;

    for s = 1:length(sequences)

        filter = query_label(sequences{s}, label);

        if isempty(filter)
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
                trajectory{end+1:length(groundtruth)} = 0;
            end;

            [~, frames] = estimate_accuracy(trajectory(filter), groundtruth(filter), 'burnin', burnin);

            accuracy(j, :) = frames;

            failures(j) = estimate_failures(trajectory(filter), sequences{s});

        end;

        frames = num2cell(accuracy, 1);
        sequence_overlaps = cellfun(@(frame) mean(frame(~isnan(frame))), frames);

        failures(isnan(failures)) = mean(failures(~isnan(failures)));

        sequence_failures = failures';

        if ~isempty(sequence_overlaps)
            A = [A, sequence_overlaps];
        end;
        
        if ~isempty(sequence_failures)
            R = [R, sequence_failures];
        end;

    end
end


function practical = practical_for_label(sequences, label)

    practical = [];

    for s = 1:length(sequences)

        filter = query_label(sequences{s}, label);

        if isempty(filter)
            continue;
        end;
        
        p = get_frame_value(sequences{s}, 'practical', filter);

        if ~isempty(p)
            practical = [practical, p];
        end;
        
    end;

end