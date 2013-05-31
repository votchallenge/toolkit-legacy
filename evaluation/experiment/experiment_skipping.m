function experiment_skipping(tracker, sequences, directory)

global track_properties;

for i = 1:length(sequences)
    print_text('Sequence "%s" (%d/%d)', sequences{i}.name, i, length(sequences));
    sequence = sequences_skipping(sequences{i}, 3);
    repeat_trial(tracker, sequence, track_properties.repeat, fullfile(directory, sequences{i}.name));
end;

