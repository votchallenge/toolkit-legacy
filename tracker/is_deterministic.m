function result = is_deterministic(sequence, repetitions, directory)

result = 1;

result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, 1));

if ~exist(result_file, 'file')
    result = 0;
    return;
end;

baseline = read_trajectory(result_file);
baseline_valid = ~cellfun(@(x) numel(x) == 1, baseline, 'UniformOutput', true);

print_debug('Checking if the tracker is deterministic ...');

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
            same = calculate_overlap(baseline(baseline_valid), trial(trial_valid)) > 0.999;
            if all(same)
                continue;
            end;
        end;
    end;    

    result = 0;
    break;

end;


