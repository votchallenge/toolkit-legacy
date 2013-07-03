function scores = experiment_grayscale(tracker, sequences, directory)

global track_properties;

sequences = cellfun(@(x) sequence_grayscale(x), sequences,'UniformOutput',false);

for i = 1:length(sequences)
    print_text('Sequence "%s" (%d/%d)', sequences{i}.name, i, length(sequences));
    repeat_trial(tracker, sequences{i}, track_properties.repeat, fullfile(directory, sequences{i}.name));
end;

scores = calculate_scores(tracker, sequences, directory);

print_text('Experiment complete.');

print_scores(sequences, scores);
