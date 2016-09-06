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
% how much does each sequence contributes to the estimate.
% - varargin[Labels] (cell): A set of labels for which to perform
% calculation. If not set then only 'all' is used.
%
% Output:
% - expected_overlaps (vector): Expected overlaps for corresponding
% lengths.
% - evaluated_lengths (vector): A filtered array of lengths (removed duplicates). 
% - practical_difference (vector): An estimate of the practical difference for
% corresponding expected overlap.

lengths = [];
weights = ones(numel(sequences), 1);
labels = {'all'};

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'lengths', lengths = varargin{j+1};
        case 'weights', weights = varargin{j+1};
        case 'labels', labels = varargin{j+1};
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
if isempty(context.practical)
  occurences = 0;
else
  occurences = hist(context.sources, max(context.sources));
end

if isempty(lengths)
    maxlen = max(cellfun(@(x) numel(x), segments, 'UniformOutput', true));
    lengths = 1:maxlen;
end

% sort and remove duplicates
lengths = unique(lengths);

skipping = experiment.parameters.skip_initialize;

fragments_count = sum(cellfun(@(x) numel(x) + 1, failures, 'UniformOutput', true));
fragments_length = max(lengths);

label_count = numel(labels);

if isempty(segments)
    expected_overlaps = zeros(0, label_count);
    practical_difference = zeros(0, label_count);
    evaluated_lengths = [];
    return;
end

expected_overlaps = zeros(numel(lengths), label_count);
practical_difference = zeros(numel(lengths), label_count);

for l = 1:label_count
    
    sequence_weights = weights(context.sources(:));
    frequency = occurences(context.sources(:));
    sequence_weights = sequence_weights(:) ./ frequency(:);

    label = labels{l};
    
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

                w = numel(query_label(sequences{context.sources(i)}, label, points(j):(points(j+1)))) ...
                    / (points(j+1) - points(j) + 1);
                
                fweights(f) = sequence_weights(i) * w;
                
                f = f + 1;
            end;

            o = segments{i}(points(end):end); o(isnan(o)) = 0;
            fragments(f, 1:min(numel(o), fragments_length)) = o;
            o = practical{i}(points(end):end); o(isnan(o)) = 0;
            fpractical(f, 1:min(numel(o), fragments_length)) = o;

            w = numel(query_label(sequences{context.sources(i)}, label, points(end):length(segments{i}))) ...
                / (sequences{context.sources(i)}.length - points(end) + 1);

            fweights(f) = sequence_weights(i) * w;
            
            f = f + 1;
        else
        % process also last part of the trajectory - segment without failure
            if numel(segments{i}) >= fragments_length
                % tracker did not fail on this sequence and it is longer than
                % observed interval
                fragments(f, :) = segments{i}(1:fragments_length);
                fpractical(f, :) = practical{i}(1:fragments_length);
                
                w = numel(query_label(sequences{context.sources(i)}, label, 1:fragments_length)) ...
                    / fragments_length;
            else
                fragments(f, 1:numel(segments{i})) = segments{i};
                fpractical(f, 1:numel(practical{i})) = practical{i};
                
                w = numel(query_label(sequences{context.sources(i)}, label)) ...
                    / sequences{context.sources(i)}.length;
            end

            fweights(f) = sequence_weights(i) * w;
            f = f + 1;
        end
    end

    for e = 1:size(expected_overlaps, 1)
        len = lengths(e);
        % do not calculate for Ns == 1: overlap on first frame is always NaN
        if len == 1
            expected_overlaps(e, l) = 1;
            continue;
        end

        usable = ~isnan(fragments(:, len));

        if ~any(usable)
            continue;
        end;
        
        % for each len get a single number - average overlap
        expected_overlaps(e, l) = sum(mean(fragments(usable, 2:len), 2) .* fweights(usable)) ./ sum(fweights(usable));
        practical_difference(e, l) = sum(mean(fpractical(usable, 2:len), 2) .* fweights(usable)) ./ sum(fweights(usable));
        
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
