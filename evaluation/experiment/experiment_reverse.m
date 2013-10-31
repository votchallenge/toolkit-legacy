function scores = experiment_reverse(tracker, sequences, directory)

global track_properties;

for i = 1:length(sequences)
    print_text('Sequence "%s" (%d/%d)', sequences{i}.name, i, length(sequences));
    sequence = sequences{i};
    sequence.groundtruth = sequence.groundtruth(end:-1:1, :);
    sequence.images = sequence.images(end:-1:1, :);
    sequence.labels.data = sequence.labels.data(end:-1:1, :);
    repeat_trial(tracker, sequence, track_properties.repeat, fullfile(directory, sequences{i}.name));
end;

scores = calculate_scores(tracker, sequences, directory);

print_text('Experiment complete.');

print_scores(sequences, scores);
