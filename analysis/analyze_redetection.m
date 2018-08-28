function [result] = analyze_redetection(experiment, trackers, sequences, varargin)
% analyze_redetection Performs redetection analysis
%
% Looks for the first failure and records how long it takes tracker to
% recover after it.
%
% Input:
% - experiment (structure): A valid experiment structures.
% - trackers (cell): A cell array of valid tracker descriptor structures.
% - sequences (cell): A cell array of valid sequence descriptor structures.
%
% Output:
% - result (structure):
%   - length (matrix): number of frames to redetecton (NaN if not
%   redetected)
%   - success (matrix): number of tries where redetection occured

    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            otherwise
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end

    print_text('Redetection analysis for experiment %s ...', experiment.name);

    print_indent(1);

    experiment_sequences = convert_sequences(sequences, experiment.converter);
    
    result.length = zeros(numel(trackers), numel(experiment_sequences));
    result.success = zeros(numel(trackers), numel(experiment_sequences));
    
    for i = 1:numel(trackers)

        print_text('Tracker %s', trackers{i}.identifier);

        for s = 1:numel(experiment_sequences)
            
            [redetected, lengths] = calculate_redetection(experiment_sequences{s}, experiment, trackers{i});

            result.length(i, s) = mean(lengths(redetected));
            result.success(i, s) = mean(redetected);
            
        end;

    end;

    print_indent(-1);

end

function [redetected, lengths] = calculate_redetection(sequence, experiment, tracker)

    repeat = experiment.parameters.repetitions;

    redetected = true(repeat);
    lengths = nan(repeat);
    result_directory = fullfile(tracker.directory, experiment.name, sequence.name);

    for r = 1:repeat

        result_file = fullfile(result_directory, sprintf('%s_%03d.txt', sequence.name, r));

        try 
            trajectory = read_trajectory(result_file);
        catch
            continue;
        end;

        [~, frames] = estimate_accuracy(trajectory, sequence, 'BindWithin', [sequence.width, sequence.height]);

        lost = find(frames == 0, 1, 'first');

        if isempty(lost)
            lengths(r) = 0;
            continue;
        end

        found = find(frames(lost:end) > 0.5, 1, 'first');

        if isempty(found)
            redetected(r) = false;
            continue;
        end
        
        lengths(r) = found;
        
    end;

end
