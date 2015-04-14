function [result] = analyze_ranks(experiment, trackers, sequences, varargin)

    usepractical = false;
    uselabels = true;
    average = 'weighted_mean';
	adaptation = 'mean';
    alpha = 0.05;
    cache = fullfile(get_global_variable('directory'), 'cache');
    
    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'uselabels'
                uselabels = varargin{i+1} ;             
            case 'usepractical'
                usepractical = varargin{i+1} ;  
            case 'average'
                average = varargin{i+1};
            case 'alpha'                
                alpha = varargin{i+1};                
            case 'cache'
                cache = varargin{i+1};                   
            case 'adaptation'
                adaptation = varargin{i+1};  
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 

    print_text('Ranking analysis for experiment %s ...', experiment.name);

    print_indent(1);

    experiment_sequences = convert_sequences(sequences, experiment.converter);

    if isfield(experiment, 'labels') && uselabels

        selectors = create_label_selectors(experiment, ...
            experiment_sequences, experiment.labels);

    else

        selectors = create_sequence_selectors(experiment, experiment_sequences);

    end;


    sequences_hash = md5hash(strjoin((cellfun(@(x) x.name, selectors, 'UniformOutput', false)), '-'), 'Char', 'hex');
    trackers_hash = md5hash(strjoin((cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');
    parameters_hash = md5hash(sprintf('%f-%s-%d-%d-%s', alpha, average, uselabels, usepractical, adaptation));
    
    mkpath(fullfile(cache, 'ranking'));
    
    cache_file = fullfile(cache, 'ranking', sprintf('%s_%s_%s_%s.mat', experiment.name, trackers_hash, sequences_hash, parameters_hash));

    result = [];
	if exist(cache_file, 'file')         
		load(cache_file);       
	end;    
    
    if isempty(result)
        [accuracy, robustness, lengths] = trackers_ranking(experiment, trackers, ...
            experiment_sequences, selectors, alpha, usepractical, average, adaptation);

        result = struct('accuracy', accuracy, 'robustness', robustness, 'lengths', lengths);

        save(cache_file, 'result');
    else
        print_text('Loading ranking results from cache.');
    end; 
        
    print_indent(-1);

end

function [accuracy, robustness, lengths] = trackers_ranking(experiment, trackers, ...
    sequences, selectors, alpha, usepractical, average, adaptation)

    N_trackers = length(trackers) ;
    N_selectors = length(selectors) ;

    % initialize accuracy outputs
    accuracy.value = zeros(N_selectors, N_trackers);
    accuracy.ranks = zeros(N_selectors, N_trackers);

    % initialize robustness outputs
    robustness.value = zeros(N_selectors, N_trackers);
    robustness.normalized = zeros(N_selectors, N_trackers);
    robustness.ranks = zeros(N_selectors, N_trackers);
    
    lengths = zeros(N_selectors, 1);
    
    for a = 1:length(selectors)
        
	    print_indent(1);

	    print_text('Processing selector %s ...', selectors{a}.name);

        % rank trackers and calculate statistical significance of differences
        [average_overlap, average_failures, average_failurerate, HA, HR, available] = ...
            trackers_raw_scores_selector(experiment, trackers, sequences, selectors{a}, alpha, usepractical);

        [~, order_by_accuracy] = sort(average_overlap(available), 'descend');
        accuracy_ranks = ones(size(available)) * length(available);
        [~, accuracy_ranks(available)] = sort(order_by_accuracy, 'ascend') ;

        [~, order_by_robustness] = sort(average_failures(available), 'ascend');
        robustness_ranks = ones(size(available)) * length(available);
        [~, robustness_ranks(available)] = sort(order_by_robustness,'ascend');  
        
        % get adapted ranks
        adapted_accuracy_ranks = adapted_ranks(accuracy_ranks, HA, adaptation);
        adapted_robustness_ranks = adapted_ranks(robustness_ranks, HR, adaptation);
        
        % mask out results that are not available
	    adapted_accuracy_ranks(~available) = nan;
	    adapted_robustness_ranks(~available) = nan;

        % write results to output structures
        accuracy.value(a, :) = average_overlap;
        accuracy.ranks(a, :) = adapted_accuracy_ranks;
        
        robustness.value(a, :) = average_failures;
        robustness.normalized(a, :) = average_failurerate;
        robustness.ranks(a, :) = adapted_robustness_ranks;
        
        lengths(a) = selectors{a}.length(sequences);
        
	    print_indent(-1);

    end

    robustness.labels = cellfun(@(x) x.name, selectors, 'UniformOutput', false);
    accuracy.labels = robustness.labels;
    
    switch average

        case 'weighted_mean'

            accuracy.average_ranks = mean(accuracy.ranks, 1);
            robustness.average_ranks = mean(robustness.ranks, 1);

            accuracy.average_value = sum(accuracy.value .* repmat(lengths, 1, length(trackers)), 1) ./ sum(lengths);
            robustness.average_value = sum(robustness.value .* repmat(lengths, 1, length(trackers)), 1) ./ sum(lengths);
            robustness.average_normalized = sum(robustness.normalized .* repmat(lengths, 1, length(trackers)), 1) ./ sum(lengths);
            
        case 'mean'

            accuracy.average_ranks = mean(accuracy.ranks, 1);
            robustness.average_ranks = mean(robustness.ranks, 1);

            accuracy.average_value = mean(accuracy.value, 1);
            robustness.average_value = mean(robustness.value, 1);
            robustness.average_normalized = mean(robustness.normalized, 1);      
                    
        case 'pool'
            
			print_text('Processing pooled frames ...');
			print_indent(1);

            pool_selector = create_label_selectors(experiment, sequences, {'all'});
            
            [average_overlap, average_failures, average_failurerate, HA, HR, available] = ...
                trackers_raw_scores_selector(experiment, trackers, sequences, pool_selector{1}, alpha, usepractical);

            [~, order_by_accuracy] = sort(average_overlap(available), 'descend');
            accuracy_ranks = ones(size(available)) * length(available);
            [~, accuracy_ranks(available)] = sort(order_by_accuracy, 'ascend') ;

            [~, order_by_robustness] = sort(average_failures(available), 'ascend');
            robustness_ranks = ones(size(available)) * length(available);
            [~, robustness_ranks(available)] = sort(order_by_robustness,'ascend');  
            
            % get adapted ranks
            adapted_accuracy_ranks = adapted_ranks(accuracy_ranks, HA, adaptation);
            adapted_robustness_ranks = adapted_ranks(robustness_ranks, HR, adaptation);

            % mask out results that are not available
            adapted_accuracy_ranks(~available) = nan;
            adapted_robustness_ranks(~available) = nan;

            % write results to output structures
            accuracy.average_value = average_overlap';
            accuracy.average_ranks = adapted_accuracy_ranks;
            robustness.average_value = average_failures';
            robustness.average_normalized = average_failurerate';
            robustness.average_ranks = adapted_robustness_ranks;
        
			print_indent(-1);

        otherwise
            
            error('Unknown averaging technique "%s"!', average);
            
    end
    
end

function [average_accuracy, average_failures, average_failurerate, HA, HR, available] ...
    = trackers_raw_scores_selector(experiment, trackers, sequences, selector, alpha, usepractical)

    cacheA = cell(length(trackers), 1);
    cacheR = cell(length(trackers), 1);
    
    HA = zeros(length(trackers)); % results of statistical testing
    HR = zeros(length(trackers)); % results of statistical testing

    average_accuracy = nan(length(trackers), 1);
    average_failures = nan(length(trackers), 1);
    average_failurerate = nan(length(trackers), 1);
    
    available = true(length(trackers), 1);
    
    if usepractical        
        practical = selector.practical(sequences);
    else
        practical = [];
    end

	print_indent(1);
    [~, lengths] = selector.length(sequences);
    
    for t1 = 1:length(trackers)

		print_text('Processing tracker %s ...', trackers{t1}.identifier);

        if isempty(cacheA{t1})
            [O1, F1] = selector.aggregate(experiment, trackers{t1}, sequences);
            cacheA{t1} = O1; cacheR{t1} = F1;
        else
            O1 = cacheA{t1}; F1 = cacheR{t1};
        end;

        if isempty(O1)
            available(t1) = false;
			HA(t1, :) = true; HA(:, t1) = true;
			HR(t1, :) = true; HR(:, t1) = true;
            continue; 
        end
        
        valid_frames = ~isnan(O1) ;

        % O1 ... stacked per-frame overlaps (already averaged over
        % repeats).
        %
        % F1 ... fragments (rows) x repeats (columns) of raw failure count.
        
        % Average accuracy is average over valid frames (non NaN).
        average_accuracy(t1) = mean(O1(valid_frames));
        
        % Average failures are sum of failures in fragments averaged over
        % repetitions
        average_failures(t1) = mean(sum(F1, 1));     
        
        % Average failure rate is sum of failures in fragments divided by
        % total length of selector, averaged over repetitions
        average_failurerate(t1) = mean(sum(F1, 1) ./ sum(lengths));
        
        for t2 = t1+1:length(trackers)
        
            if isempty(cacheA{t1})
                [O1, F1] = selector.aggregate(experiment, trackers{t1}, sequences);
                cacheA{t1} = O1; cacheR{t1} = F1;
            else
                O1 = cacheA{t1}; F1 = cacheR{t1};
            end;

            if isempty(cacheA{t2})
                [O2, F2] = selector.aggregate(experiment, trackers{t2}, sequences);
                cacheA{t2} = O2; cacheR{t2} = F2;
            else
                O2 = cacheA{t2}; F2 = cacheR{t2};
            end;                

            if isempty(O2)
                available(t2) = false; 
                continue; 
            end

            % If alpha is 0 then we disable the equivalence testing
            if alpha <= 0
            
                ha = true; hr = true;
                
            else
                
                [ha, hr] = compare_trackers(O1, F1, O2, F2, alpha, practical);

            end;
            
            HA(t1, t2) = ha; HA(t2, t1) = HA(t1, t2);
            HR(t1, t2) = hr; HR(t2, t1) = HR(t1, t2);               
        end;
    end;

	print_indent(-1);  

end


