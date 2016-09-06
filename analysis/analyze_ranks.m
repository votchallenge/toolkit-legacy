function [result] = analyze_ranks(experiment, trackers, sequences, varargin)
% analyze_ranks Performs ranking analysis
%
% Performs ranking analysis for a given experiment on a set trackers and sequences.
%
% Input:
% - experiment (structure): A valid experiment structures.
% - trackers (cell): A cell array of valid tracker descriptor structures.
% - sequences (cell): A cell array of valid sequence descriptor structures.
% - varargin[Labels] (cell): An array of label names that should be used
% instead of sequences.
% - varargin[UsePractical] (boolean): Use practical difference for accuracy.
% - varargin[Alpha] (double): Statistical significance parameter.
% - varargin[Adaptation] (string): Type of rank adaptation. See
% adapter_ranks for more details.
%
% Output:
% - result (structure): A structure with the following fields
%     - accuracy
%          - values: average overlap matrix
%          - ranks: accuracy ranks matrix
%     - robustness
%          - values: number of failures matrix
%          - ranks: robustness ranks matrix
%     - lengths: number of frames for individual selectors
%     - labels: names of individual selectors

    usepractical = false;
    labels = {};
	adaptation = 'mean';
    alpha = 0.05;

    for i = 1:2:length(varargin)
        switch lower(varargin{i})
            case 'labels'
                labels = varargin{i+1} ;             
            case 'usepractical'
                usepractical = varargin{i+1} ;  
            case 'alpha'                
                alpha = varargin{i+1};
            case 'adaptation'
                adaptation = varargin{i+1};  
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 
    
    print_text('Ranking analysis for experiment %s ...', experiment.name);
    
    if ~strcmp(experiment.type, 'supervised')
        error('Ranking analysis can only be used in supervised experiment scenario.');
    end;
    
    if experiment.parameters.repetitions < 5
        error('The experiment specifies less than 5 repetitions. Not valid for statistical consideration.');
    end
    
    if experiment.parameters.repetitions < 15
        print_text('Warning: the experiment specifies less than 15 repetitions, the results may be statistically unstable.');
    end;
    
    print_indent(1);

    experiment_sequences = convert_sequences(sequences, experiment.converter);

    if ~isempty(labels)

        labels = unique(labels); % Remove any potential duplicates.
        
        selectors = create_label_selectors(experiment, ...
            experiment_sequences, labels);

    else

        selectors = create_sequence_selectors(experiment, experiment_sequences);

    end;

    [accuracy, robustness, lengths] = trackers_ranking(experiment, trackers, ...
        experiment_sequences, selectors, alpha, usepractical, adaptation);

    result = struct('accuracy', accuracy, 'robustness', robustness, 'lengths', lengths);
    result.labels = cellfun(@(x) x.name, selectors, 'UniformOutput', false);
        
    print_indent(-1);

end

function [accuracy, robustness, lengths] = trackers_ranking(experiment, trackers, ...
    sequences, selectors, alpha, usepractical, adaptation)

    N_trackers = length(trackers) ;
    N_selectors = length(selectors) ;

    % initialize accuracy outputs
    accuracy.values = zeros(N_selectors, N_trackers);
    accuracy.ranks = zeros(N_selectors, N_trackers);

    % initialize robustness outputs
    robustness.values = zeros(N_selectors, N_trackers);
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
        accuracy.values(a, :) = average_overlap;
        accuracy.ranks(a, :) = adapted_accuracy_ranks;
        
        robustness.values(a, :) = average_failures;
        robustness.normalized(a, :) = average_failurerate;
        robustness.ranks(a, :) = adapted_robustness_ranks;
        
        lengths(a) = selectors{a}.length(sequences);
        
	    print_indent(-1);

    end
    
end

function [average_accuracy, average_failures, average_failurerate, HA, HR, available] ...
    = trackers_raw_scores_selector(experiment, trackers, sequences, selector, alpha, usepractical)

    cacheA = cell(length(trackers), 1);
    cacheR = cell(length(trackers), 1);
    
    HA = false(length(trackers)); % results of statistical testing
    HR = false(length(trackers)); % results of statistical testing

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
            HA(t1, t1) = false; HR(t1, t1) = false;
            continue; 
        end
        
        valid_frames = ~isnan(O1) ;

        % O1 ... stacked per-frame overlaps (already averaged over
        % repeats).
        %
        % F1 ... fragments (rows) x repeats (columns) of raw failure count.
        
        % Average accuracy is average over valid frames (non NaN).
	if all(valid_frames == 0)
		average_accuracy(t1) = 0;
	else
		average_accuracy(t1) = mean(O1(valid_frames));
	end;
        
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
            
                ha = true; hr = true; hp = 0;
                
            else
                
                [ha, hr] = test_significance(O1, F1, O2, F2, alpha, practical);

            end;
            
            HA(t1, t2) = ha; HA(t2, t1) = HA(t1, t2);
            HR(t1, t2) = hr; HR(t2, t1) = HR(t1, t2);               
        end;
    end;

	print_indent(-1);  

    average_accuracy(isnan(average_accuracy)) = 0;
            
    
end

function [ha, hr, hp] = test_significance(A1, R1, A2, R2, alpha, practical)
% test_significance Verify difference of A-R performance for two trackers
%
% Compare A-R performance of two trackers taking into account statistical
% and practical difference of results.
%
% Input:
% - A1 (double matrix): Per-frame accuracy for first tracker
% - R1 (double matrix): Per-segment robustness for first tracker
% - A2 (double matrix): Per-frame accuracy for second tracker
% - R2 (double matrix): Per-segment robustness for second tracker
% - alpha (double): Confidence parameter
% - practical (boolean): Take into account practical difference for the
% frames
%
% Output:
% - ha (boolean): Is accuracy different
% - hr (boolean): Is robustness different
% - hp (number): Number of frames for which the practical difference test
% was positive
%
 
    % Testing accuracy significance

    % Statistical test
    dif = A1 - A2;
    valid = ~isnan(dif);
    dif = dif(valid) ;
    if (length(dif) < 25)
        print_text('Warning: less than 25 samples when comparing trackers. Cannot reject hypothesis');
        ha = 1;
    else
        if (is_octave)
            try
            pa = wilcoxon_test(A1(valid), A2(valid));
            ha = (pa <= alpha);
            catch
                %A1(valid) - A2(valid)
                %pa = 0;
                ha = 1;
            end;
        else
            [~, ha, ~] = signrank(dif, [], 'alpha', alpha ) ;
        end;
    end;               

    hp = 0;
    
    % Practical difference of accuracy
    if ~isempty(practical)
        hp = sum(dif' < practical(valid));
        if abs(mean(dif' ./ practical(valid))) < 1
            ha = 0;
        end;

    end;

    % Testing robustness significance
    R1 = R1(:);
    R2 = R2(:);
    if (is_octave)
       pr = u_test(R1, R2);
       hr = (pr <= alpha);
    else
       [~, hr] = ranksum(R1, R2, 'alpha', alpha) ;
    end;

end
