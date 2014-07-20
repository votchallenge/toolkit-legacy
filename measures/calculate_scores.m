function [scores] = calculate_scores(tracker, sequences, result_directory)

performance = readstruct(benchmark_hardware(tracker));

scores = nan(length(sequences), 3);
repeat = get_global_variable('repeat', 1);
burnin = get_global_variable('burnin', 0);

for i = 1:length(sequences)

    directory = fullfile(result_directory, sequences{i}.name);

    accuracy = nan(repeat, 1);
    reliability = nan(repeat, 1);

    for j = 1:repeat

        result_file = fullfile(directory, sprintf('%s_%03d.txt', sequences{i}.name, j));
        
        try 
            trajectory = read_trajectory(result_file);
        catch
            continue;
        end;

        accuracy(j) = estimate_accuracy(trajectory, sequences{i}, 'burnin', burnin);
        reliability(j) = estimate_failures(trajectory, sequences{i});

    end;

    times = csvread(fullfile(directory, sprintf('%s_time.txt', sequences{i}.name)));
    
    if all(isnan(reliability))
        continue;
    end;

    valid = any(times > 0, 1) & ~isnan(reliability)';
    average_speed = mean(times(:, valid), 1)';   
    reliability = reliability(valid);
 
    average_speed = normalize_speed(average_speed, reliability, tracker, sequences{i}, performance);

    average_speed = mean(average_speed);    

    if isnan(average_speed) || average_speed == 0
        average_speed = NaN;
    else
        average_speed = 1 / average_speed;
    end;
    
    scores(i, :) = [mean(accuracy(~isnan(accuracy))), mean(reliability(~isnan(reliability))), average_speed];

end;


