function [S_all, nFailures_all, available] = process_results_labels(trackers, sequences, labels, experiment)

repeat = get_global_variable('repeat', 1);
burnin = get_global_variable('burnin', 0);

S_all = cell(length(labels), 1);
nFailures_all = cell(length(labels), 1);

available = true(length(trackers), 1);

for l = 1:length(labels)
    
    label = labels{l};

    print_indent(1);

    print_text('Processing label %s', label);

    label_overlaps = nan(length(trackers), 0);
    label_failures = nan(length(trackers), 0);    
    
    for s = 1:length(sequences)

        filter = query_label(sequences{s}, label);

        if isempty(filter)
            continue;
        end;
        
        print_indent(1);

        groundtruth = sequences{s}.groundtruth;

        sequence_overlaps = nan(length(trackers), length(filter));
        sequence_failures = nan(length(trackers), repeat);

        print_text('Processing sequence %s', sequences{s}.name);

        for t = 1:length(trackers)

            if ~exist(fullfile(trackers{t}.directory, experiment), 'dir')
                print_debug('Warning: Results not available %s', trackers{t}.identifier);
                available(t) = 0;
                continue;
            end;
            
            directory = fullfile(trackers{t}.directory, experiment, sequences{s}.name);

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
            sequence_overlaps(t, :) = cellfun(@(frame) mean(frame(~isnan(frame))), frames);

            failures(isnan(failures)) = mean(failures(~isnan(failures)));

            sequence_failures(t, :) = failures;

        end;

        if ~isempty(sequence_overlaps)
            label_overlaps = [label_overlaps sequence_overlaps];
        end;
        if ~isempty(sequence_failures)
            label_failures = [label_failures sequence_failures];
        end;

        print_indent(-1);

    end;

    S_all{l} = label_overlaps;
    nFailures_all{l} = label_failures;

    print_indent(-1);
    
end;
