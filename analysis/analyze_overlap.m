function [result] = analyze_overlap(experiment, trackers, sequences, varargin)
% analyze_overlap Performs overlap analysis
%
% Performs overlap analysis for a given experiment on a set trackers and sequences.
% This analysis is performed on an unsupervised experiment, it is very similar to
% the overlap analysis, proposed in the OTB benchmark, in fact it is more accurate
% since the computation is not computed on a fixed number of points.
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
%     - curves: overlap threshold curves
%     - thresholds: corresponding thresholds (x values)
%     - auc: computed AUC values
%

    resolution = 100;
    tags = {};

    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'tags'
                tags = varargin{i+1};
            case 'resolution'
                resolution = varargin{i+1} ;
            otherwise
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end

    print_text('Overlap analysis for experiment %s ...', experiment.name);

    print_indent(1);

    experiment_sequences = convert_sequences(sequences, experiment.converter);

    if ~isempty(tags)

        tags = unique(tags); % Remove any potential duplicates.

        selectors = sequence_tag_selectors(experiment, ...
            experiment_sequences, tags);

    else

        selectors = sequence_selectors(experiment, experiment_sequences);

    end;

    result.thresholds = linspace(0, 1, resolution);
    result.curves = zeros(numel(trackers), numel(selectors), resolution);
    result.auc = zeros(numel(trackers), numel(selectors));
    result.selectors = cellfun(@(x) x.name, selectors, 'UniformOutput', false);
    
    for i = 1:numel(trackers)

        print_text('Tracker %s', trackers{i}.identifier);

        for s = 1:numel(selectors)
            
            [curves, auc] = calculate_auc(selectors{s}, experiment, trackers{i}, experiment_sequences, result.thresholds);

            result.curves(i, s, :) = curves;
            result.auc(i, s) = auc;

        end;

    end;

    print_indent(-1);

end

function [curve, auc] = calculate_auc(selector, experiment, tracker, sequences, thresholds)

    aggregated_overlap = [];

    groundtruth = selector.groundtruth(sequences);
    trajectories = selector.results(experiment, tracker, sequences);

    repeat = experiment.parameters.repetitions;
    burnin = experiment.parameters.burnin;
    
    for s = 1:numel(groundtruth)

        accuracy = nan(repeat, length(groundtruth{s}));

        for r = 1:size(trajectories, 2)

            if isempty(trajectories{s, r})
                continue;
            end;

            [~, frames] = estimate_accuracy(trajectories{s, r}, groundtruth{s}, 'burnin', burnin, 'BindWithin', [sequences{s}.width, sequences{s}.height]);

            accuracy(r, :) = frames;

        end;

        frames = num2cell(accuracy, 1);
        sequence_overlaps = cellfun(@(frame) nanmean(frame), frames);

        if ~isempty(sequence_overlaps)
            aggregated_overlap = [aggregated_overlap, sequence_overlaps]; %#ok<AGROW>
        end;

    end;

    N = selector.length(sequences);
    aggregated_overlap(isnan(aggregated_overlap)) = 0;

    if isempty(aggregated_overlap)
        curve = zeros(numel(thresholds), 1);
        auc = 0;
        return;
    end
    
    curve = sum(bsxfun(@(x, y) x > y, aggregated_overlap', thresholds), 1) ./ N;
    auc = mean(aggregated_overlap);
    
end
