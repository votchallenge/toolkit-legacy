function experiment_baseline(tracker, sequences, directory)

global track_properties;

for i = 1:length(sequences)
    print_text('Sequence "%s" (%d/%d)', sequences{i}.name, i, length(sequences));
    repeat_trial(tracker, sequences{i}, track_properties.repeat, fullfile(directory, sequences{i}.name));
end;

