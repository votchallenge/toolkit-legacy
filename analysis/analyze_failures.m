function [failure_histograms] = analyze_failures(experiment, trackers, sequences)
% analyze_failures Perform failure frequency analysis
%
% This function performs failure frequency analysis for a set of trackers
% on a set of sequences and experiments.
%
% Input:
% - experiment (cell): A cell array of valid experiment structures.
% - trackers (cell): A cell array of valid tracker descriptor structures.
% - sequences (cell): A cell array of valid sequence descriptor structures.
%
% Output:
% - failure_histograms (cell): A cell array (one element for each experiment) of cell arrays (one for each sequence) of double matrices that contain per-frame failure frequencies for all trackers.   
%

    repeat = experiment.parameters.repetitions;

    print_text('Failure analysis for experiment %s ...', experiment.name);

    experiment_sequences = convert_sequences(sequences, experiment.converter);
        
    failure_histograms = cell(1, numel(experiment_sequences));
    
    for s = 1:length(experiment_sequences)

        print_indent(1);

        failure_histogram = zeros(numel(trackers), experiment_sequences{s}.length);
        
        print_text('Processing sequence %s ...', experiment_sequences{s}.name);

        for t = 1:length(trackers)

            print_indent(1);

            result_directory = fullfile(trackers{t}.directory, experiment.name, experiment_sequences{s}.name);
            
            for j = 1:repeat

                result_file = fullfile(result_directory, sprintf('%s_%03d.txt', experiment_sequences{s}.name, j));
                
                try 
                    trajectory = read_trajectory(result_file);
                catch
                    continue;
                end;

                if length(trajectory) < experiment_sequences{s}.length
                    trajectory{end+1:experiment_sequences{s}.length} = 0;
                end;
                
                [~, failures] = estimate_failures(trajectory, experiment_sequences{s});
                failures = failures(failures <= experiment_sequences{s}.length);
                failure_histogram(t, failures) = failure_histogram(t, failures) + 1;

            end;

            failure_histograms{s} = failure_histogram;
            
            print_indent(-1);

        end;

        print_indent(-1);
        
    end;
