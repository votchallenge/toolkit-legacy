function result = is_deterministic(sequence, repetitions, directory)

result = 1;

result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, 1));

if ~exist(result_file, 'file')
    result = 0;
    return;
end;

baseline = csvread(result_file);

for i = 2:repetitions

    result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, i));

    if ~exist(result_file, 'file')
        result = 0;
        break;
    end;

    trial = csvread(result_file);

    if all(size(baseline) == size(trial))
        if all(baseline == trial)
            continue;
        end;
    end;    

    result = 0;
    break;

end;


