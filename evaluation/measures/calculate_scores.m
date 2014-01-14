function [scores] = calculate_scores(tracker, sequences, result_directory)

scores = nan(length(sequences), 3);
repeat = get_global_variable('repeat', 1);
burnin = get_global_variable('burnin', 0);

for i = 1:length(sequences)

    directory = fullfile(result_directory, sequences{i}.name);

    accuracy = nan(repeat, 1);
    reliability = nan(repeat, 1);

    for j = 1:repeat

        result_file = fullfile(directory, sprintf('%s_%03d.txt', sequences{i}.name, j));
        trajectory = load_trajectory(result_file);

        if isempty(trajectory)
            continue;
        end;

        accuracy(j) = estimate_accuracy(trajectory, sequences{i}, 'burnin', burnin);
        reliability(j) = estimate_failures(trajectory, sequences{i});

    end;

    times = csvread(fullfile(directory, sprintf('%s_time.txt', sequences{i}.name)));
    
    if all(isnan(reliability))
        continue;
    end;

    average_time = mean(times(times > 0));
    if isempty(average_time)
        average_time = NaN;
    end;
    
    scores(i, :) = [mean(accuracy(~isnan(accuracy))), mean(reliability(~isnan(reliability))), average_time];

end;


