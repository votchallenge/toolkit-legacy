function scores = experiment_skipping(tracker, sequences, directory)

global track_properties;

sequences = cellfun(@(x) sequence_skipping(x, 3), sequences,'UniformOutput',false);

for i = 1:length(sequences)
    print_text('Sequence "%s" (%d/%d)', sequences{i}.name, i, length(sequences));
    sequence = sequences{i};
    repeat_trial(tracker, sequence, track_properties.repeat, fullfile(directory, sequences{i}.name));
end;

scores = calculate_scores(tracker, sequences, directory);

print_text('Experiment complete. Outputting final A-R scores:');

print_indent(1);

for i = 1:length(sequences)
    print_text('Sequence "%s" - Accuracy: %.3f, Reliability: %.3f', sequences{i}.name, scores(i, 1), scores(i, 2));
end;

print_indent(-1);
