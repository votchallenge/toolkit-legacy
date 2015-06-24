function [failure_histograms] = analyze_failures(experiment, trackers, sequences, varargin)
% analyze_failures Perform failure frequency analysis
%
% This function performs failure frequency analysis for a set of trackers
% on a set of sequences and experiments.
%
% Input:
% - experiment (cell): A cell array of valid experiment structures.
% - trackers (cell): A cell array of valid tracker descriptor structures.
% - sequences (cell): A cell array of valid sequence descriptor structures.
% - varargin[Cache] (string): Path to cache directory.
%
% Output:
% - failure_histograms (cell): A cell array (one element for each experiment) of cell arrays (one for each sequence) of double matrices that contain per-frame failure frequencies for all trackers.   
%

    cache = fullfile(get_global_variable('directory'), 'cache');
    
    for i = 1:2:length(varargin)
        switch lower(varargin{i})               
            case 'cache'
                cache = varargin{i+1};                   
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 


    repeat = experiment.parameters.repetitions;

    print_text('Failure analysis for experiment %s ...', experiment.name);

    sequences_hash = md5hash(strjoin((cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');
    trackers_hash = md5hash(strjoin((cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');
    
    mkpath(fullfile(cache, 'failures'));
    
    cache_file = fullfile(cache, 'failures', sprintf('%s_%s_%s.mat', experiment.name, trackers_hash, sequences_hash));

    failure_histograms = [];
	if exist(cache_file, 'file')         
		load(cache_file);       
	end;       
    
    if ~isempty(failure_histograms)
        print_text('Loading failure analysis results from cache.');
        return;
    end; 
    
    experiment_sequences = convert_sequences(sequences, experiment.converter);
        
    failure_histograms = cell(1, numel(experiment_sequences));
    
    for s = 1:length(experiment_sequences)

        print_indent(1);

        failure_histogram = zeros(numel(trackers), experiment_sequences{s}.length);
        
        print_text('Processing sequence %s ...', experiment_sequences{s}.name);

        for t = 1:length(trackers)

            print_indent(1);

            result_directory = fullfile(trackers{t}.directory, experiment.name, experiment_sequences{s}.name);
            
            for j = 1:repeat

                result_file = fullfile(result_directory, sprintf('%s_%03d.txt', experiment_sequences{s}.name, j));
                
                try 
                    trajectory = read_trajectory(result_file);
                catch
                    continue;
                end;

                if length(trajectory) < experiment_sequences{s}.length
                    trajectory{end+1:experiment_sequences{s}.length} = 0;
                end;
                
                [~, failures] = estimate_failures(trajectory, experiment_sequences{s});
                
                failure_histogram(t, failures) = failure_histogram(t, failures) + 1;

            end;

            failure_histograms{s} = failure_histogram;
            
            print_indent(-1);

        end;

        print_indent(-1);
        
    end;

    save(cache_file, 'failure_histograms');
    
