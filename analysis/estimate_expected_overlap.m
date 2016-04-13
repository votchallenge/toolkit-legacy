function [expected_overlaps, evaluated_lengths, practical_difference] = estimate_expected_overlap(tracker, experiment, sequences, varargin)
% estimate_expected_overlap Estimates expected average overlap for
% different sequence lengths
%
% This function estimates the expected average overlap for sequence of a
% given lengths based on the data
%
% Input:
% - tracker (struct): A valid tracker descriptor.
% - experiment (struct): A valid experiment descriptor.
% - sequences (cell): An array of valid sequence descriptors.
% - varargin[Lengths] (vector): A vector of sequence lengths for which the
% overlap should be evaluated.
% - varargin[Weights] (vector): A vector of per-sequence weigths that indicate
% how much does each sequence contribute to the estimate. Can also be a
% matrix, the number of columns is in this case the number of different
% weighting schemes. The functon will in this case return expected_overlaps
% and practical_difference in form of matrices with the number of columns
% corresponding to the number of weighting schemes.
%
% Output:
% - expected_overlaps (vector): Expected overlaps for corresponding
% lengths.
% - evaluated_lengths (vector): A filtered array of lengths (removed duplicates). 
% - practical_difference (vector): An estimate of the practical difference for
% corresponding expected overlap.

lengths = [];
weights = ones(numel(sequences), 1);

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'lengths', lengths = varargin{j+1};
        case 'weights', weights = varargin{j+1};
        otherwise, error(['unrecognized argument ' varargin{j}]);
    end
end

context.failures = {};
context.overlaps = {};
context.practical = {};
context.sources = [];
context = iterate(experiment, tracker, sequences, 'iterator', @collect_segments, 'context', context);
failures = context.failures;
segments = context.overlaps;
practical = context.practical;
occurences = hist(context.sources, max(context.sources));

if isempty(lengths)
    maxlen = max(cellfun(@(x) numel(x), segments, 'UniformOutput', true));
    lengths = 1:maxlen;
end

% sort and remove duplicates
lengths = unique(lengths);

skipping = experiment.parameters.skip_initialize;

fragments_count = sum(cellfun(@(x) numel(x) + 1, failures, 'UniformOutput', true));
fragments_length = max(lengths);

reweightings = size(weights, 2);

if isempty(segments)
    expected_overlaps = zeros(0, reweightings);
    practical_difference = zeros(0, reweightings);
    evaluated_lengths = [];
    return;
end

expected_overlaps = zeros(numel(lengths), reweightings);
practical_difference = zeros(numel(lengths), reweightings);

for v = 1:reweightings
    
    segment_weights = weights(context.sources, v)' ./ occurences(context.sources);

    fragments = nan(fragments_count, fragments_length);
    fpractical = nan(fragments_count, fragments_length);
    fweights = nan(fragments_count, 1);
    f = 1;
    for i = 1:numel(segments)
        % calculate number of failures and their positions in the trajectory
        F = numel(failures{i});
        if F > 0
            % add first part of the trajectory to the fragment list
            points = failures{i}' + skipping;
            points = [1, points(points <= numel(segments{i}))];

            for j = 1:numel(points)-1;
                o = segments{i}(points(j):points(j+1)); o(isnan(o)) = 0;
                fragments(f, :) = 0;
                fragments(f, 1:min(numel(o), fragments_length)) = o;

                o = practical{i}(points(j):points(j+1)); o(isnan(o)) = 0;
                fpractical(f, :) = 0;
                fpractical(f, 1:min(numel(o), fragments_length)) = o;

                fweights(f) = segment_weights(i);

                f = f + 1;
            end;

            o = segments{i}(points(end):end); o(isnan(o)) = 0;
            fragments(f, 1:min(numel(o), fragments_length)) = o;
            o = practical{i}(points(end):end); o(isnan(o)) = 0;
            fpractical(f, 1:min(numel(o), fragments_length)) = o;

            fweights(f) = segment_weights(i);

            f = f + 1;
        else
        % process also last part of the trajectory - segment without failure
            if numel(segments{i}) >= fragments_length
                % tracker did not fail on this sequence and it is longer than
                % observed interval
                fragments(f, :) = segments{i}(1:fragments_length);
                fpractical(f, :) = practical{i}(1:fragments_length);
            else
                fragments(f, 1:numel(segments{i})) = segments{i};
                fpractical(f, 1:numel(practical{i})) = practical{i};
            end
            fweights(f) = segment_weights(i);
            f = f + 1;
        end
    end

    for e = 1:size(expected_overlaps, 1)
        len = lengths(e);
        % do not calculate for Ns == 1: overlap on first frame is always NaN
        if len == 1
            expected_overlaps(e, v) = 1;
            continue;
        end

        usable = ~isnan(fragments(:, len));

        % for each len get a single number - average overlap
        expected_overlaps(e, v) = sum(mean(fragments(usable, 2:len), 2) .* fweights(usable)) ./ sum(fweights(usable));
        practical_difference(e, v) = sum(mean(fpractical(usable, 2:len), 2) .* fweights(usable)) ./ sum(fweights(usable));
        
    end

end

evaluated_lengths = lengths;

end

function context = collect_segments(event, context)

switch (event.type)
        
    case 'sequence_enter'
        
        sequence = event.sequence;

        sequence_directory = fullfile(event.tracker.directory, event.experiment.name, ...
            sequence.name);
        
        switch event.experiment.type
            case 'supervised'
                
                for i = 1:event.experiment.parameters.repetitions
                    
                    result_file = fullfile(sequence_directory, sprintf('%s_%03d.txt', event.sequence.name, i));

                    if i == 4 && is_deterministic(sequence, 3, sequence_directory)
                        break;
                    end;
                    
                    if ~exist(result_file, 'file')
                        continue;
                    end;
                    
                    trajectory = read_trajectory(result_file);
                    
                    [~, frames] = estimate_accuracy(trajectory, sequence);
                    
                    [~, failures] = estimate_failures(trajectory, sequence);

                    practical = get_frame_value(sequence, 'practical');
                    
                    context.failures{end+1} = failures(failures <= sequence.length);
                    context.overlaps{end+1} = frames;
                    context.sources(end+1) = event.sequence_index;
                    
                    if isempty(practical)
                        context.practical{end+1} = zeros(sequence.length, 1);
                    else
                        context.practical{end+1} = practical;
                    end
                    
                end;

            otherwise, error(['unrecognized type ' type]);
        end
        
end;

end
