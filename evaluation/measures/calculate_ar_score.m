function [scores] = calculate_ar_score(tracker, sequences, result_directory)

global track_properties;

scores = nan(length(sequences), 2);

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

        accuracy(j) = estimate_accuracy(trajectory, sequences{i}, 'burnout', track_properties.burnout);
        reliability(j) = estimate_reliability(trajectory, sequences{i});

    end;

    if all(isnan(accuracy))
        continue;
    end;

    scores(i, :) = [mean(accuracy(~isnan(accuracy))), mean(reliability(~isnan(reliability)))];

end;


