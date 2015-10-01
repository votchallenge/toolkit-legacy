function [expected_overlaps, evaluated_lengths] = estimate_expected_overlap(tracker, experiment, sequences, varargin)
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
%
% Output:
% - expected_overlaps (vector): Expected overlaps for corresponding
% lengths.
% - evaluated_lengths (vector): A filtered array of lengths (removed duplicates). 

lengths = [];

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'lengths', lengths = varargin{j+1};
        otherwise, error(['unrecognized argument ' varargin{j}]);
    end
end

context.failures = {};
context.overlaps = {};
context = iterate(experiment, tracker, sequences, 'iterator', @collect_segments, 'context', context);
failures = context.failures;
overlaps = context.overlaps;

if isempty(lengths)
    maxlen = max(cellfun(@(x) numel(x), overlaps, 'UniformOutput', true));
    lengths = 1:maxlen;
end

% sort and remove duplicates
lengths = unique(lengths);

skipping = experiment.parameters.skip_initialize;

fragments_count = sum(cellfun(@(x) numel(x) + 1, failures, 'UniformOutput', true));
fragments_length = max(lengths);

fragments = nan(fragments_count, fragments_length);
f = 1;
for i = 1:numel(overlaps)
    % calculate number of failures and their positions in the trajectory
    F = numel(failures{i});
    if F > 0
        % add first part of the trajectory to the fragment list
        points = failures{i}' + skipping;
        points = [1, points(points <= numel(overlaps{i}))];
        
        for j = 1:numel(points)-1;
            o = overlaps{i}(points(j):points(j+1));
            o(isnan(o)) = 0;
            fragments(f, :) = 0;
            fragments(f, 1:min(numel(o), fragments_length)) = o;
            f = f + 1;
        end;

        o = overlaps{i}(points(end):end);
        o(isnan(o)) = 0;
        fragments(f, 1:min(numel(o), fragments_length)) = o;
        f = f + 1;
    else
    % process also last part of the trajectory - segment without failure
        if numel(overlaps{i}) >= fragments_length
            % tracker did not fail on this sequence and it is longer than
            % observed interval
            fragments(f, :) = overlaps{i}(1:fragments_length);
        else
            fragments(f, 1:numel(overlaps{i})) = overlaps{i};            
        end
        f = f + 1;
    end
end

% w is vector of weights (can be used in per-visual property calculation)
% if weights are not given - use equal weights
w = ones(size(fragments, 1), 1);

expected_overlaps = zeros(numel(lengths), 1);
for e = 1:numel(expected_overlaps)
    len = lengths(e);
    % do not calculate for Ns == 1: overlap on first frame is always NaN
    if len == 1
        expected_overlaps(e) = 1;
        continue;
    end

    usable = ~isnan(fragments(:, len));
    
    % for each len get a single number - average overlap
    expected_overlaps(e) = sum(mean(fragments(usable, 2:len), 2) .* w(usable)) ./ sum(w(usable));
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
                    
                    if ~exist(result_file, 'file')
                        continue;
                    end;
                    
                    if i == 4 && is_deterministic(sequence, 3, sequence_directory)
                        break;
                    end;
                    
                    trajectory = read_trajectory(result_file);
                    
                    [~, frames] = estimate_accuracy(trajectory, sequence);
                    
                    [~, failures] = estimate_failures(trajectory, sequence);

                    context.failures{end+1} = failures;
                    context.overlaps{end+1} = frames;
                    
                end;

            otherwise, error(['unrecognized type ' type]);
        end
        
end;

end
