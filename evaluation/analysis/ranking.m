function [A, R] = ranking(S, F, labels, varargin)

display_results = 0 ;
type_comparison = 'Wilcoxon' ; % Wilcoxon,  Prob_better
minimal_difference_acc = 0 ;% minimal difference at which two trackers are actually different
alpha = 0.05 ;

for i = 1 :2: length(varargin)
    switch varargin{i}
        case 'alpha'
            alpha = varargin{i+1} ;
        case 'minimal_difference_acc'
            minimal_difference_acc = varargin{i+1} ;
        case 'minimal_difference_fail'
            minimal_difference_fail = varargin{i+1} ;            
         case 'type_comparison'
            type_comparison = varargin{i+1} ;   
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

N_trackers = size(S{1},1) ;
N_sequences = length(S) ;

% initialize accuracy outputs
A.mu = zeros(N_sequences, N_trackers) ;
A.std = zeros(N_sequences, N_trackers) ;
A.ranks = zeros(N_sequences, N_trackers) ;
% initialize robustness outputs
R.mu = zeros(N_sequences, N_trackers) ;
R.std = zeros(N_sequences, N_trackers) ;
R.ranks = zeros(N_sequences, N_trackers) ;
  
for i_seq = 1 : length(S)
    
    % rank trackers and calculate statistical significance of differences
    [H_acc, H_fail, accuracy_ranks, failure_ranks, average_results] = ...
        compare_pairs( S{i_seq}, F{i_seq}, labels, ...
                   'minimal_difference_acc', minimal_difference_acc, ...
                   'minimal_difference_fail', minimal_difference_fail,...
                   'alpha', alpha, 'display_results', display_results,...
                   'type_comparison', type_comparison) ;
    
    % get adapted ranks
    adapted_rank_acc  = adapted_ranks(accuracy_ranks, H_acc) ;
    adapted_rank_fail = adapted_ranks(failure_ranks, H_fail) ;   
    
    % write results to output structures
    A.mu(i_seq, :) = average_results.average_accuracy.mu ;
    A.std(i_seq, :) = average_results.average_accuracy.std ;
    A.ranks(i_seq, :) = adapted_rank_acc ;
  
    R.mu(i_seq, :) = average_results.average_failures.mu ;
    R.std(i_seq, :) = average_results.average_failures.std ;        
    R.ranks(i_seq, :) = adapted_rank_fail ;    
end
A.average_ranks = mean(A.ranks,1) ;
R.average_ranks = mean(R.ranks,1) ;

