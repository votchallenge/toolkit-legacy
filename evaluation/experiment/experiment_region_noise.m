function scores = experiment_region_noise(tracker, sequences, directory)

global track_properties;

noise_file = fullfile(fileparts(mfilename('fullpath')), 'noise.txt');

if exist(noise_file, 'file')
        print_debug('Reading noise from noise.txt ...');
    noise = csvread(noise_file);
else
    print_debug('WARNING: noise.txt not found! Generating random noise ...');
    noise = generate_noise(track_properties.repeat * length(sequences));
end;

for i = 1:length(sequences)
    print_text('Sequence "%s" (%d/%d)', sequences{i}.name, i, length(sequences));
    sequence = sequences{i};
    sequence.initialize = @initialize_noise;
    if size(noise, 1) >= track_properties.repeat * length(sequences)
        sequence.noise = noise(((i-1) * track_properties.repeat + 1):(i * track_properties.repeat), :);
    else
        sequence.noise = noise(randperm(size(noise, 1)), :);
    end;
    repeat_trial(tracker, sequence, track_properties.repeat, fullfile(directory, sequences{i}.name));
end;

scores = calculate_scores(tracker, sequences, directory);

print_text('Experiment complete.');

print_scores(sequences, scores);
