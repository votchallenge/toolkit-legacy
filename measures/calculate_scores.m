function [scores] = calculate_scores(tracker, sequences, result_directory)

if ~isfield(tracker, 'performance')
    tracker.performance = readstruct(benchmark_hardware(tracker));
end;

scores = nan(length(sequences), 4);
repeat = get_global_variable('repeat', 1);
burnin = get_global_variable('burnin', 0);

for i = 1:length(sequences)

    directory = fullfile(result_directory, sequences{i}.name);

    accuracy = nan(repeat, 1);
    reliability = nan(repeat, 1);
	failures = cell(repeat, 1);

    for j = 1:repeat

        result_file = fullfile(directory, sprintf('%s_%03d.txt', sequences{i}.name, j));
        
        try 
            trajectory = read_trajectory(result_file);
        catch
            continue;
        end;

        accuracy(j) = estimate_accuracy(trajectory, sequences{i}, 'burnin', burnin);
        [reliability(j), failures{j}] = estimate_failures(trajectory, sequences{i});

    end;

    times = csvread(fullfile(directory, sprintf('%s_time.txt', sequences{i}.name)));
    
    if all(isnan(reliability))
        continue;
    end;

    valid = any(times > 0, 1) & ~isnan(reliability)';
    average_speed = mean(times(:, valid), 1)';   
    reliability = reliability(valid);
 
    [normalized_speed, actual_speed] = normalize_speed(average_speed, failures(valid), tracker, sequences{i});

    normalized_speed = mean(normalized_speed);
    actual_speed = mean(actual_speed);

    if isnan(normalized_speed) || normalized_speed == 0
        normalized_speed = NaN;
        actual_speed = NaN;
    else
        normalized_speed = 1 / normalized_speed;
        actual_speed = 1 / actual_speed;
    end;
    
    scores(i, :) = [mean(accuracy(~isnan(accuracy))), mean(reliability(~isnan(reliability))), normalized_speed, actual_speed];

end;