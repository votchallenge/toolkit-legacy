function scores = experiment_loss_black(tracker, sequences, directory)
% This VOT experiment sets every third frame in the sequence to black

global track_properties;

sequences = cellfun(@(x) sequence_pixelchange(x, @loss_black), sequences,'UniformOutput',false);

for i = 1:length(sequences)
    print_text('Sequence "%s" (%d/%d)', sequences{i}.name, i, length(sequences));
    repeat_trial(tracker, sequences{i}, track_properties.repeat, fullfile(directory, sequences{i}.name));
end;

scores = calculate_scores(tracker, sequences, directory);

print_text('Experiment complete.');

print_scores(sequences, scores);

end

function T = loss_black(I, i, len)

    T = I;
    
    if mod(i, 3) == 0
        T(:, :, :) = 0;
    end;
    
end
