function [result] = analyze_expected_overlap(experiment, trackers, sequences, varargin)
% analyze_expected_overlap Performs expected overlap analysis
%
% Performs expected overlap analysis for a given experiment on a set trackers and sequences.
%
% Input:
% - experiment (structure): A valid experiment structures.
% - trackers (cell): A cell array of valid tracker descriptor structures.
% - sequences (cell): A cell array of valid sequence descriptor structures.
% - varargin[UseLabels] (boolean): Perform per-label 
% - varargin[Lengths] (vector): Lengths for which to evaluated expected overlap.
% - varargin[Cache] (string): Cache directory.
%
% Output:
% - result (structure): A structure with the following fields
%     - curves: expected overlap curves
%     - practical: corresponding practical differences
%     - lengths: lengths for which the expected overlap was evaluated
%

    uselabels = true;
    lengths = [];
    cache = fullfile(get_global_variable('directory'), 'cache');
    
    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'uselabels'
                uselabels = varargin{i+1};
            case 'lengths'
                lengths = varargin{i+1};
            case 'cache'
                cache = varargin{i+1};   
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 
    
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
    
    for i = 1:numel(trackers)
        
        print_text('Tracker %s', trackers{i}.identifier);
        
        sequences_hash = calculate_results_fingerprint(trackers{i}, experiment, experiment_sequences);
        
        cache_file = fullfile(cache, 'expected_overlap', sprintf('%s_%s_%s_%s.mat',  trackers{i}.identifier, experiment.name, sequences_hash, lengths_hash));

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
        
        [expected_overlaps, evaluated_lengths, practical_difference] = ...
            estimate_expected_overlap(trackers{i}, experiment, experiment_sequences, 'Lengths', lengths);
        
        if ~isempty(cache_file)
            save(cache_file, 'evaluated_lengths', 'expected_overlaps');
        end
        
        result.curves{i} = expected_overlaps;
        result.practical{i} = practical_difference;
        result.lengths = evaluated_lengths;
    end;

    print_indent(-1);

end
