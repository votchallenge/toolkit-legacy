function [S_all, nFailures_all, available] = process_results_sequences(trackers, sequences, experiment)

repeat = get_global_variable('repeat', 1);
burnin = get_global_variable('burnin', 0);

S_all = cell(length(sequences), 1);
nFailures_all = cell(length(sequences), 1);

available = true(length(trackers), 1);
 
for s = 1:length(sequences)

    sequence = sequences{s};

    print_indent(1);

    print_text('Processing sequence %s', sequence.name);

    groundtruth = sequence.groundtruth;

    sequence_overlaps = nan(length(trackers), sequence.length);
    sequence_failures = nan(length(trackers), repeat);

    for t = 1:length(trackers)

        if ~exist(fullfile(trackers{t}.directory, experiment), 'dir')
            print_debug('Warning: Results not available %s', trackers{t}.identifier);
            available(t) = 0;
            continue;
        end;

        directory = fullfile(trackers{t}.directory, experiment, sequence.name);

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
                trajectory{end+1:length(groundtruth)} = 0;
            end;

            [~, frames] = estimate_accuracy(trajectory, groundtruth, 'burnin', burnin);

            accuracy(j, :) = frames;

            failures(j) = estimate_failures(trajectory, sequence);

        end;

        frames = num2cell(accuracy, 1);
        sequence_overlaps(t, :) = cellfun(@(frame) mean(frame(~isnan(frame))), frames);

        failures(isnan(failures)) = mean(failures(~isnan(failures)));

        sequence_failures(t, :) = failures;

    end;

    S_all{s} = sequence_overlaps;
    nFailures_all{s} = sequence_failures;

    print_indent(-1);
    
end;
