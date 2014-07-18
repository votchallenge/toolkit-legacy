function [accuracy, robustness, available] = trackers_ranking(experiment, trackers, sequences, aspects, varargin)

alpha = 0.05 ;
usepractical = false;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'alpha'
            alpha = varargin{i+1} ;
        case 'usepractical'
            practical = varargin{i+1} ;            
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

N_trackers = length(trackers) ;
N_aspects = length(aspects) ;

% initialize accuracy outputs
accuracy.mu = zeros(N_aspects, N_trackers) ;
accuracy.std = zeros(N_aspects, N_trackers) ;
accuracy.ranks = zeros(N_aspects, N_trackers) ;

% initialize robustness outputs
robustness.mu = zeros(N_aspects, N_trackers) ;
robustness.std = zeros(N_aspects, N_trackers) ;
robustness.ranks = zeros(N_aspects, N_trackers) ;



for a = 1:length(aspects)
    
    % rank trackers and calculate statistical significance of differences
    [average_accuracy, average_robustness, accuracy_ranks, robustness_ranks, HA, HR, available] = ...
        trackers_ranking_aspect(experiment, trackers, sequences, aspects{a}, 'alpha', alpha, 'usepractical', usepractical);
    
    % get adapted ranks
    adapted_accuracy_ranks = adapted_ranks(accuracy_ranks, HA) ;
    adapted_robustness_ranks = adapted_ranks(robustness_ranks, HR) ;   
    
    % write results to output structures
    accuracy.mu(a, :) = average_accuracy.mu ;
    accuracy.std(a, :) = average_accuracy.std ;
    accuracy.ranks(a, :) = adapted_accuracy_ranks ;
  
    robustness.mu(a, :) = average_robustness.mu ;
    robustness.std(a, :) = average_robustness.std ;        
    robustness.ranks(a, :) = adapted_robustness_ranks ;
    
end

accuracy.average_ranks = mean(accuracy.ranks,1) ;
robustness.average_ranks = mean(robustness.ranks,1) ;

end

function [average_accuracy, average_robustness, accuracy_ranks, robustness_ranks, HA, HR, available] = trackers_ranking_aspect(experiment, trackers, sequences, aspect, varargin)

    alpha = 0.05 ;
    usepractical = true;
    
    cache_directory = fullfile(get_global_variable('directory'), 'cache', 'ranking', experiment.name, aspect.name);    
    mkpath(cache_directory);

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

    average_accuracy.mu = zeros(length(trackers), 1);
    average_accuracy.std = zeros(length(trackers), 1);
    
    average_robustness.mu = zeros(length(trackers), 1);
    average_robustness.std = zeros(length(trackers), 1);
    
    available = true(length(trackers), 1);
    
    if usepractical        
        practical = aspect.practical(sequences);
    else
        practical = [];
    end

    for t1 = 1:length(trackers)

        cache_file = fullfile(cache_directory, sprintf('%s.txt', trackers{t1}.identifier));
        
        if ~exist(cache_file, 'file')
        
            if isempty(cacheA{t1})
                [A1, R1] = aspect.aggregate(experiment, trackers{t1}, sequences);
                cacheA{t1} = A1; cacheR{t1} = R1;
            else
                A1 = cacheA{t1}; R1 = cacheR{t1};
            end;

            if isempty(A1)
                available(t1) = false;
                continue; 
            end
            
            valid_frames = ~isnan(A1) ;

            average_accuracy.mu(t1) = mean(A1(valid_frames));
            average_accuracy.std(t1) = std(A1(valid_frames));

            average_robustness.mu(t1) = mean(R1);
            average_robustness.std(t1) = std(R1);
        
            csvwrite(cache_file, [average_accuracy.mu(t1), average_accuracy.std(t1); ...
                average_robustness.mu(t1), average_robustness.std(t1)]);
            
        else
            
            cache = csvread(cache_file);
            
            average_accuracy.mu(t1) = cache(1, 1);
            average_accuracy.std(t1) = cache(1, 2);

            average_robustness.mu(t1) = cache(2, 1);
            average_robustness.std(t1) = cache(2, 2);
            
        end;
        
        for t2 = t1+1:length(trackers)
        
            cache_file = fullfile(cache_directory, sprintf('%s-%s.txt', trackers{t1}.identifier, trackers{t2}.identifier));
        
            if ~exist(cache_file, 'file')

                if isempty(cacheA{t1})
                    [A1, R1] = aspect.aggregate(experiment, trackers{t1}, sequences);
                    cacheA{t1} = A1; cacheR{t1} = R1;
                else
                    A1 = cacheA{t1}; R1 = cacheR{t1};
                end;

                if isempty(cacheA{t2})
                    [A2, R2] = aspect.aggregate(experiment, trackers{t2}, sequences);
                    cacheA{t2} = A2; cacheR{t2} = R2;
                else
                    A2 = cacheA{t2}; R2 = cacheR{t2};
                end;                

                if isempty(A2)
                    available(t2) = false;
                    continue; 
                end                

                
                [ha, hr] = compare_trackers(A1, R1, A2, R2, alpha, practical);
         
                csvwrite(cache_file, [ha, hr]);
                
            else
                
                cache = csvread(cache_file);
                
                ha = cache(1);
                hr = cache(2);
                
            end;
            
            HA(t1, t2) = ha; HA(t2, t1) = HA(t1, t2);
            HR(t1, t2) = hr; HR(t2, t1) = HR(t1, t2);               
        end;
    end;

    [~, order_by_accuracy] = sort(average_accuracy.mu, 'descend');
    [~, accuracy_ranks] = sort(order_by_accuracy, 'ascend') ;

    [~, order_by_robustness] = sort(average_robustness.mu, 'ascend');
    [~, robustness_ranks] = sort(order_by_robustness,'ascend');    
    
end



