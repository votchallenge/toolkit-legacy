function [result] = analyze_precision_recall(experiment, trackers, sequences, varargin)
% analyze_precision_recall Performs tracking precision and recall analysis
%
% Performs tracking precision-recall analysis for a given experiment on a set trackers and sequences.
%
% Input:
% - experiment (structure): A valid experiment structures.
% - trackers (cell): A cell array of valid tracker descriptor structures.
% - sequences (cell): A cell array of valid sequence descriptor structures.
% - varargin[Tags] (cell): An array of tag names that should be used
% instead of sequences.
%
% Output:
% - result (structure): A structure with the following fields
%     - 
%     - lengths: number of frames for individual selectors
%     - tags: names of individual selectors

    resolution = [];
    tags = {};

    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'tags'
                tags = varargin{i+1};
            case 'resolution'
                resolution = varargin{i+1};
            otherwise
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end

    print_text('Tracking precision-recall analysis for experiment %s ...', experiment.name);

    print_indent(1);

    experiment_sequences = convert_sequences(sequences, experiment.converter);

    if ~isempty(tags)

        tags = unique(tags); % Remove any potential duplicates.

        selectors = sequence_tag_selectors(experiment, ...
            experiment_sequences, tags);

    else

        selectors = sequence_selectors(experiment, experiment_sequences);

    end;

    result.curves = cell(numel(trackers), numel(selectors));
    result.measures = zeros(numel(trackers), numel(selectors), 3);
    result.selectors = cellfun(@(x) x.name, selectors, 'UniformOutput', false);
    
    
    for i = 1:numel(trackers)

        print_text('Tracker %s', trackers{i}.identifier);

        thresholds = [];
        
        if ~isempty(resolution)
            thresholds = determine_thresholds(experiment, trackers{i}, experiment_sequences, resolution);
        end

        for s = 1:numel(selectors)
            
            [curves, measures] = calculate_tpr_fscore(selectors{s}, experiment, trackers{i}, experiment_sequences, thresholds);

            result.curves{i, s} = curves;
            result.measures(i, s, :) = measures;

        end;

    end;

    print_indent(-1);

end

function [thresholds] = determine_thresholds(experiment, tracker, sequences, resolution)

    confidence_name = 'confidence';

    if isfield(tracker.metadata, 'confidence')
       
        confidence_name = tracker.metadata.confidence;
        
    end
    
    selector = sequence_tag_selectors(experiment, sequences, {'all'});

    values = selector{1}.results_values(experiment, tracker, sequences, confidence_name);
    
    certanty = zeros(sum(cellfun(@numel, values(:, 1), 'UniformOutput', true)), size(values, 2));

    i = 1;
    
    for s = 1:size(values, 1)

        for r = 1:size(values, 2)

            if isempty(values{s, r})
                continue;
            end;

            certanty(i:i+size(values{s, r})-1, r) = values{s, r};
            i = i + size(values{s, r});

        end;
    end;
    
    thresholds = sort(certanty(~isnan(certanty)));
    
    if numel(thresholds) > resolution
        delta = floor(numel(thresholds) / (resolution - 2));
        idxs = round(linspace(delta, numel(thresholds)-delta, resolution-2));
        thresholds = thresholds(idxs);
    end
    
    if isempty(thresholds)
        thresholds = ones(resolution-2, 1);
    end
    
    thresholds = [-Inf; thresholds; Inf];
end

function [curve, measures, fbest] = calculate_tpr_fscore(selector, experiment, tracker, sequences, thresholds)

    confidence_name = 'confidence';
    confidence_inverse = false;
    
    if isfield(tracker.metadata, 'confidence')
       
        confidence_name = tracker.metadata.confidence;
        
    end
    
    if isfield(tracker.metadata, 'confidence_inverse')
       
        confidence_inverse = tracker.metadata.confidence_inverse;
        
    end
    
    groundtruth = selector.groundtruth(sequences);
    trajectories = selector.results(experiment, tracker, sequences);

    values = selector.results_values(experiment, tracker, sequences, confidence_name);
 
    overlaps = zeros(sum(cellfun(@numel, groundtruth, 'UniformOutput', true)), size(trajectories, 2));
    certanty = zeros(size(overlaps));
    
    i = 1;
    
    N = 0;
    
    for s = 1:numel(groundtruth)

        for r = 1:size(trajectories, 2)

            if isempty(trajectories{s, r})
                continue;
            end;

            [~, frames] = estimate_accuracy(trajectories{s, r}, groundtruth{s}, ...
                'BindWithin', [sequences{s}.width, sequences{s}.height]);

            frames(isnan(frames)) = 0;
            
            overlaps(i:i+size(groundtruth{s})-1, r) = frames;
            if ~isempty(values{s, r})
                certanty(i:i+size(groundtruth{s})-1, r) = values{s, r};
            end

        end;

        i = i + size(groundtruth{s});

        if ~isempty(groundtruth{s})
            N = N + sum(cellfun(@(x) numel(x) > 1, groundtruth{s}, 'UniformOutput', true));
        end;
    end;

    if isempty(thresholds)
       thresholds = certanty(~isnan(certanty));
    end
    
    thresholds = sort(thresholds, iff(confidence_inverse, 'ascend', 'descend'));
    
    curve = zeros(numel(thresholds), 3);
    
    curve(:, 3) = thresholds;
    
    for k = 1:numel(thresholds)

        % indicator vector where to calculate Pr-Re
        subset = certanty >= thresholds(k);

        if sum(subset) == 0
            % special case - no prediction is made:
            % Precision is 1 and Recall is 0
            curve(k,1) = 1;
            curve(k,2) = 0;
        else
            curve(k, 1) = mean(overlaps(subset));
            curve(k, 2) = sum(overlaps(subset)) ./ N;
        end

    end

    f = 2 * (curve(:, 1) .* curve(:, 2)) ./ (curve(:, 1) + curve(:, 2));
    
    [fmax, fidx] = max(f);
    
    measures = [fmax, curve(fidx, 1), curve(fidx, 2)];
    fbest = thresholds(fidx);
    
 end
