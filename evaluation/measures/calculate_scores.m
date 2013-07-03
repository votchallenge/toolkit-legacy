function [scores] = calculate_scores(tracker, sequences, result_directory)

global track_properties;

scores = nan(length(sequences), 3);

for i = 1:length(sequences)

    directory = fullfile(result_directory, sequences{i}.name);

    accuracy = nan(track_properties.repeat, 1);
    reliability = nan(track_properties.repeat, 1);

    for j = 1:track_properties.repeat

        result_file = fullfile(directory, sprintf('%s_%03d.txt', sequences{i}.name, j));
        trajectory = load_trajectory(result_file);

        if isempty(trajectory)
            continue;
        end;

        accuracy(j) = estimate_accuracy(trajectory, sequences{i}, 'burnin', track_properties.burnin);
        reliability(j) = estimate_failures(trajectory, sequences{i});

    end;

    times = csvread(fullfile(directory, sprintf('%s_time.txt', sequences{i}.name)));
    
    if all(isnan(accuracy))
        continue;
    end;

    scores(i, :) = [mean(accuracy(~isnan(accuracy))), mean(reliability(~isnan(reliability))), mean(times(times > 0))];

end;


