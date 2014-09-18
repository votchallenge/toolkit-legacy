function [accuracy, robustness] = trackers_ranking(experiment, trackers, sequences, selectors, varargin)

alpha = 0.05 ;
usepractical = false;
average = 'mean';

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'alpha'
            alpha = varargin{i+1} ;
        case 'usepractical'
            usepractical = varargin{i+1} ;            
        case 'average'
            average = varargin{i+1} ;              
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

N_trackers = length(trackers) ;
N_selectors = length(selectors) ;

% initialize accuracy outputs
accuracy.mu = zeros(N_selectors, N_trackers) ;
accuracy.std = zeros(N_selectors, N_trackers) ;
accuracy.ranks = zeros(N_selectors, N_trackers) ;

% initialize robustness outputs
robustness.mu = zeros(N_selectors, N_trackers) ;
robustness.std = zeros(N_selectors, N_trackers) ;
robustness.ranks = zeros(N_selectors, N_trackers) ;

for a = 1:length(selectors)
    
	print_indent(1);

	print_text('Processing selector %s ...', selectors{a}.name);

    % rank trackers and calculate statistical significance of differences
    [average_accuracy, average_robustness, accuracy_ranks, robustness_ranks, HA, HR, available] = ...
        trackers_ranking_selector(experiment, trackers, sequences, selectors{a}, 'alpha', alpha, 'usepractical', usepractical);
    
    % get adapted ranks
    adapted_accuracy_ranks = adapted_ranks(accuracy_ranks, HA) ;
    adapted_robustness_ranks = adapted_ranks(robustness_ranks, HR) ;   
    
    % mask out results that are not available
	adapted_accuracy_ranks(~available) = nan;
	adapted_robustness_ranks(~available) = nan;

    % write results to output structures
    accuracy.value(a, :) = average_accuracy.mu;
    accuracy.error(a, :) = average_accuracy.std;
    accuracy.ranks(a, :) = adapted_accuracy_ranks;
    
    robustness.value(a, :) = average_robustness.mu;
    robustness.error(a, :) = average_robustness.std;        
    robustness.ranks(a, :) = adapted_robustness_ranks;
    robustness.length = selectors{a}.length(sequences);
    
	print_indent(-1);

end

switch average
    
    case 'mean'

        accuracy.average_ranks = mean(accuracy.ranks, 1) ;
        robustness.average_ranks = mean(robustness.ranks, 1) ;

        accuracy.average_value = mean(accuracy.value, 1) ;
        robustness.average_value = mean(robustness.value, 1) ;        
                
    case 'gather'
        
        gather_selector = create_label_selectors(experiment, sequences, {'all'});
        
        [average_accuracy, average_robustness, accuracy_ranks, robustness_ranks, HA, HR, available] = ...
            trackers_ranking_selector(experiment, trackers, sequences, gather_selector{1}, 'alpha', alpha, 'usepractical', usepractical);

        % get adapted ranks
        adapted_accuracy_ranks = adapted_ranks(accuracy_ranks, HA) ;
        adapted_robustness_ranks = adapted_ranks(robustness_ranks, HR) ;   

        % mask out results that are not available
        adapted_accuracy_ranks(~available) = nan;
        adapted_robustness_ranks(~available) = nan;

        % write results to output structures
        accuracy.average_value = average_accuracy.value;
        accuracy.average_error = average_accuracy.error;
        accuracy.average_ranks = adapted_accuracy_ranks;
        robustness.average_value = average_robustness.value;
        robustness.average_error = average_robustness.error; 
        robustness.average_ranks = adapted_robustness_ranks;
    
end
    
end

function [average_accuracy, average_robustness, accuracy_ranks, robustness_ranks, HA, HR, available] = trackers_ranking_selector(experiment, trackers, sequences, selector, varargin)

    alpha = 0.05 ;
    usepractical = false;

    for i = 1:2:length(varargin)
        switch varargin{i}
            case 'alpha'
                alpha = varargin{i+1} ;               
            case 'usepractical'
                usepractical = varargin{i+1} ;                 
            otherwise 
                error(['Unknown switch ', varargin{i},'!']) ;
        end
    end 

    cacheA = cell(length(trackers), 1);
    cacheR = cell(length(trackers), 1);
    
    HA = zeros(length(trackers)); % results of statistical testing
    HR = zeros(length(trackers)); % results of statistical testing

    average_accuracy.mu = nan(length(trackers), 1);
    average_accuracy.std = nan(length(trackers), 1);
    
    average_robustness.mu = nan(length(trackers), 1);
    average_robustness.std = nan(length(trackers), 1);
    
    available = true(length(trackers), 1);
    
    if usepractical        
        practical = selector.practical(sequences);
    else
        practical = [];
    end

	print_indent(1);

    for t1 = 1:length(trackers)

		print_text('Processing tracker %s ...', trackers{t1}.identifier);

            if isempty(cacheA{t1})
                [A1, R1] = selector.aggregate(experiment, trackers{t1}, sequences);
                cacheA{t1} = A1; cacheR{t1} = R1;
            else
                A1 = cacheA{t1}; R1 = cacheR{t1};
            end;

            if isempty(A1)
                available(t1) = false;
				HA(t1, :) = true; HA(:, t1) = true;
				HR(t1, :) = true; HR(:, t1) = true;
                continue; 
            end
            
            valid_frames = ~isnan(A1) ;

            average_accuracy.mu(t1) = mean(A1(valid_frames));
            average_accuracy.std(t1) = std(A1(valid_frames));

            average_robustness.mu(t1) = mean(R1);
            average_robustness.std(t1) = std(R1);

        
        for t2 = t1+1:length(trackers)
        
            if isempty(cacheA{t1})
                [A1, R1] = selector.aggregate(experiment, trackers{t1}, sequences);
                cacheA{t1} = A1; cacheR{t1} = R1;
            else
                A1 = cacheA{t1}; R1 = cacheR{t1};
            end;

            if isempty(cacheA{t2})
                [A2, R2] = selector.aggregate(experiment, trackers{t2}, sequences);
                cacheA{t2} = A2; cacheR{t2} = R2;
            else
                A2 = cacheA{t2}; R2 = cacheR{t2};
            end;                

            if isempty(A2)
                available(t2) = false; 
                continue; 
            end

            [ha, hr] = compare_trackers(A1, R1, A2, R2, alpha, practical);

            HA(t1, t2) = ha; HA(t2, t1) = HA(t1, t2);
            HR(t1, t2) = hr; HR(t2, t1) = HR(t1, t2);               
        end;
    end;

	print_indent(-1);

    [~, order_by_accuracy] = sort(average_accuracy.mu(available), 'descend');
	accuracy_ranks = ones(size(available)) * length(available);
    [~, accuracy_ranks(available)] = sort(order_by_accuracy, 'ascend') ;

    [~, order_by_robustness] = sort(average_robustness.mu(available), 'ascend');
	robustness_ranks = ones(size(available)) * length(available);
    [~, robustness_ranks(available)] = sort(order_by_robustness,'ascend');    

end



