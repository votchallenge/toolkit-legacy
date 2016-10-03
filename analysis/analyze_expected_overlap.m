function [result] = analyze_expected_overlap(experiment, trackers, sequences, varargin)
% analyze_expected_overlap Performs expected average overlap analysis
%
% Performs expected average overlap analysis for a given experiment on a set trackers and sequences.
%
% Input:
% - experiment (structure): A valid experiment structure.
% - trackers (cell): A cell array of valid tracker descriptor structures.
% - sequences (cell): A cell array of valid sequence descriptor structures.
% - varargin[Labels] (cell): An array of label names to be considered.
% - varargin[Lengths] (vector): Lengths for which to evaluated expected overlap.
% - varargin[Aggregation] (string): Aggregation method, either pooled or mean
% - varargin[Cache] (string): Cache directory.
%
% Output:
% - result (structure): A structure with the following fields
%     - curves: expected overlap curves
%     - practical: corresponding practical differences
%     - lengths: lengths for which the expected overlap was evaluated
%

    labels = {'all'};
    lengths = [];
    cache = fullfile(get_global_variable('directory'), 'cache');
    aggregation = 'pooled';    

    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'labels'
                labels = varargin{i+1};
            case 'lengths'
                lengths = varargin{i+1};
            case 'aggregation'
                aggregation = varargin{i+1};
            case 'cache'
                cache = varargin{i+1};   
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 
    
    if ~strcmp(experiment.type, 'supervised')
        error('Ranking analysis can only be used in supervised experiment scenario.');
    end;
    
    print_text('Expected overlap analysis for experiment %s ...', experiment.name);

    print_indent(1);

    experiment_sequences = convert_sequences(sequences, experiment.converter);

    mkpath(fullfile(cache, 'expected_overlap'));

    if isempty(lengths)
        maxlen = max(cellfun(@(x) x.length, experiment_sequences, 'UniformOutput', true));
        lengths = 1:maxlen;
    end
    
    result.curves = cell(numel(trackers), 1);
    result.practical = cell(numel(trackers), 1);
    lengths_hash = md5hash(lengths);
    
    labels_hash = md5hash(strjoin(labels, ';'));
    
    parameters_hash = md5hash(sprintf('%s', aggregation));

    for i = 1:numel(trackers)
        
        print_text('Tracker %s', trackers{i}.identifier);
        
        sequences_hash = calculate_results_fingerprint(trackers{i}, experiment, experiment_sequences);
        
        hash_hash = md5hash( strjoin({sequences_hash, lengths_hash, labels_hash, parameters_hash}) );
        cache_file = fullfile(cache, 'expected_overlap', sprintf('%s_%s_%s.mat', ...
            trackers{i}.identifier, experiment.name, hash_hash));

        expected_overlaps = [];
        evaluated_lengths = [];
        practical_difference = [];
        if exist(cache_file, 'file')
            load(cache_file);       
        end;    

        if ~isempty(expected_overlaps) && ~isempty(evaluated_lengths) && ~isempty(practical_difference)
            result.curves{i} = expected_overlaps;
            result.practical{i} = practical_difference;
            result.lengths = evaluated_lengths;
            continue;
        end;
        
        switch lower(aggregation)
        case 'pooled'

            [expected_overlaps, evaluated_lengths, practical_difference] = ...
                estimate_expected_overlap(trackers{i}, experiment, experiment_sequences, ...
                'Lengths', lengths, 'Labels', labels);

        case 'mean'
            maxlen = max(cellfun(@(x) x.length, sequences, 'UniformOutput', true));
            lengths = 1:maxlen;
            accumulator = nan(numel(lengths), numel(labels), numel(sequences));

            for j = 1:numel(sequences)
                overlap = estimate_expected_overlap(trackers{i}, experiment, sequences(j), 'Lengths', lengths, 'Labels', labels);
                if (size(overlap,1) == 0)
                  accumulator(:, :, j) = NaN;
                else
                  accumulator(:, :, j) = overlap;
                end;
            end;

            expected_overlaps = nanmean(accumulator, 3);
            evaluated_lengths = lengths;
            practical_difference = zeros(size(expected_overlaps)); % TODO

        case 'wmean'
            maxlen = max(cellfun(@(x) x.length, sequences, 'UniformOutput', true));
            lengths = 1:maxlen;
            accumulator = nan(numel(lengths), numel(labels), numel(sequences));

            for j = 1:numel(sequences)
                overlap = estimate_expected_overlap(trackers{i}, experiment, sequences(j), 'Lengths', lengths, 'Labels', labels);
                if (size(overlap,1) == 0)
                  accumulator(:, :, j) = NaN;
                else
                  accumulator(:, :, j) = overlap;
                end;
            end;

			weights = cellfun(@(x) x.length, sequences, 'UniformOutput', true);
            expected_overlaps = nansum(accumulator .* repmat(reshape(weights, [1, 1, numel(sequences)]), [numel(lengths), numel(labels), 1]), 3) ./ sum(weights);
            evaluated_lengths = lengths;
            practical_difference = zeros(size(expected_overlaps)); % TODO

        otherwise
            error('Illegal aggregation mode');
        end;

        if ~isempty(cache_file)
            save(cache_file, 'evaluated_lengths', 'expected_overlaps', 'practical_difference');
        end
        
        result.curves{i} = expected_overlaps;
        result.practical{i} = practical_difference;
        result.lengths = evaluated_lengths;
    end;

    print_indent(-1);

end
