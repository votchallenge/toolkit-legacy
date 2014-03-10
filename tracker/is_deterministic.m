function result = is_deterministic(sequence, repetitions, directory)

result = 1;

result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, 1));

if ~exist(result_file, 'file')
    result = 0;
    return;
end;

baseline = csvread(result_file);
baseline_valid = ~isnan(baseline(:, 1));

print_debug('Checking if the tracker is deterministic ...');

for i = 2:repetitions

    result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, i));

    if ~exist(result_file, 'file')
        result = 0;
        break;
    end;

    trial = csvread(result_file);

    if all(size(baseline) == size(trial))
        trial_valid = ~isnan(trial(:, 1));
        if all(baseline_valid == trial_valid)
            same = baseline(baseline_valid, :) == trial(trial_valid, :);
            if all(same(:))
                continue;
            end;
        end;
    end;    

    result = 0;
    break;

end;


