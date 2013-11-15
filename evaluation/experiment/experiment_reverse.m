function scores = experiment_reverse(tracker, sequences, directory)

global track_properties;

sequences = cellfun(@(x) sequence_reverse(x), sequences,'UniformOutput',false);

for i = 1:length(sequences)
    print_text('Sequence "%s" (%d/%d)', sequences{i}.name, i, length(sequences));
    repeat_trial(tracker, sequences{i}, track_properties.repeat, fullfile(directory, sequences{i}.name));
end;

scores = calculate_scores(tracker, sequences, directory);

print_text('Experiment complete.');

print_scores(sequences, scores);

end

function reversed_sequence = sequence_reverse(sequence)

	reversed_sequence = sequence;
    reversed_sequence.groundtruth = sequence.groundtruth(end:-1:1, :);
    reversed_sequence.images = sequence.images(end:-1:1, :);
    reversed_sequence.labels.data = sequence.labels.data(end:-1:1, :);

end
