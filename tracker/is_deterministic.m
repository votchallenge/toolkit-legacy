function result = is_deterministic(sequence, repetitions, directory)
% is_deterministic Test if a tracker is deterministic
%
% Test if a tracker is deterministic for a given sequence. This is done by considering
% first three trajectories for a given sequence and checking if the regions are equivalent
% for every frame.
%
% Input:
% - sequence: A sequence structure.
% - repetitions: An integer number denoting the maximum number of repetitions.
% - directory: A full path to the directory containing the results for the sequence.
%
% Output
% - result: True if the tracker is deterministic.

result = 1;

result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, 1));

if ~exist(result_file, 'file')
    result = 0;
    return;
end;

bind_within = get_global_variable('bounded_overlap', true);
baseline = read_trajectory(result_file);
baseline_valid = ~cellfun(@(x) numel(x) == 1, baseline, 'UniformOutput', true);

if bind_within
    bounds = [sequence.width, sequence.height] - 1;
else
    bounds = [];
end;

for i = 2:repetitions

    result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, i));

    if ~exist(result_file, 'file')
        result = 0;
        break;
    end;

    trial = read_trajectory(result_file);

    if all(size(baseline) == size(trial))
        trial_valid = ~cellfun(@(x) numel(x) == 1, trial, 'UniformOutput', true);
        if all(baseline_valid == trial_valid)
            same = calculate_overlap(baseline(baseline_valid), trial(trial_valid), bounds) > 0.999;
            if all(same)
                continue;
            end;
        end;
    end;    

    result = 0;
    break;

end;


