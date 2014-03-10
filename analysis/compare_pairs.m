function [Hacc, Hfail, Racc, Rfail, average_results] = compare_pairs...
                            ( S, F, varargin )
% 1. Rank trackers by average accuracy
% 2. Perform paired Wilcoxon test on pairs of trackers
% 3. Display number of failures per tracker as well and rank them
% == Input:
% S ... matrix of errors. Each row contains per-frame errors of a single
% tracker
% nFailures ... matrix of failures (sequence per row and repetition per column): in case of stochastic trackers, there
% will be multiple failure measurements per sequence. In case of deterministic tracker, set all columns in a row to the same value. 
% minimal_difference ... difference at which two tracker's errors are
% considered different
% t_labels ... tracker names
% display_results ... [0,1] should we display intermediate results
% == Output: 
% H_acc ... Matrix of H0 rejection (1 means that we reject H0 that trackers are equal at alpha value)
% P_acc ... Matrix of p-values 
% rank_by_fail ... ordering by failure rate (best is first)
% rank_acc ... ordering by accuracy (best is first)
% average_results ... average results by sequences

type_comparison = 'Wilcoxon' ; % Wilcoxon,  Prob_better
test_fail = 1 ;
alpha = 0.05 ;
minimal_difference_acc = 0 ;
minimal_difference_fail = 0 ;

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
        case 'test_fail'
            test_fail = varargin{i+1} ;
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 
 
N_trackers = size(S,1) ;
ValidFrames = ~isnan(S) ;
% homogenize invalid frames ?
% ValidFrames = repmat(sum(ValidFrames==0)==0, size(ValidFrames,1),1) ;

S0 = S ;
S0(~ValidFrames) = 0 ;

for i = 1 : N_trackers        
    average_accuracy.mu(i) = mean( S0(i,ValidFrames(i,:)) ) ;
    average_accuracy.std(i) = std( S0(i,ValidFrames(i,:)) ) ;
end

% sort by accuracy: larger is better
[~, ordr_by_acc] = sort(average_accuracy.mu, 'descend') ;
[~,Racc]=sort(ordr_by_acc,'ascend') ;
 
% check whether pairs are statistically different in accuracy
[ Hacc, ~ ] = compare_pairs_statistical_significance(...
        N_trackers, S, type_comparison, alpha, minimal_difference_acc, 'paired-prob') ;

% check whether pairs are different in failure rate
if (test_fail == 1)
    [ Hfail, ~ ] = ...
        compare_pairs_statistical_significance(...
        N_trackers, F, type_comparison, alpha, minimal_difference_fail, 'nonpaired') ;
else
    Hfail = Hacc*0 ;
    for i = 1 : N_trackers
        for j = i + 1 : N_trackers
            Hfail(i,j) = abs(F(i)-F(j)) <= minimal_difference_fail ;
            Hfail(j,i) = Hfail(i,j) ;
        end
    end
end

average_failures.mu = mean(F,2) ;
average_failures.std = std(F,0,2) ;

[~, order_by_fail] = sort(average_failures.mu, 'ascend') ;
[~, Rfail] = sort(order_by_fail,'ascend') ;
 
average_results.average_accuracy = average_accuracy ;
average_results.average_failures = average_failures ;
 
% ----------------------------------------------------------------------- %
function [ H, P ] = compare_pairs_statistical_significance(N_trackers, S, ...
                                        type_comparison, alpha, minimal_difference, pairing)

H = zeros(N_trackers) ; % results of statistical testing
P = zeros(N_trackers) ; % results of statistical testing


for i = 1 : N_trackers
    for j = i+1 : N_trackers
        switch type_comparison
            case 'Wilcoxon'
                switch pairing
                    case 'paired'                    
                        dif = S(i,:)-S(j,:) ;
                        dif = dif(~isnan(dif)) ;
                        if (length(dif) < 5)
                            print_text('Warning: less than 5 samples comparing tracker %d and %d', i, j);
                            p = 1;
                            h = 0;
                        else
                        if (is_octave)
                            [p, h] = wilcoxon_test(S(i,:), S(j,:));
                        else
                            [p, h, ~] = signrank(dif, [], 'alpha', alpha ) ;
                        end;
                        end;
                    case 'paired-mean'
                        dif = S(i,:)-S(j,:) ;
                        dif = dif(~isnan(dif)) ;
                        if (length(dif) < 5)
                            print_text('Warning: less than 5 samples comparing tracker %d and %d', i, j);
                            p = 1;
                            h = 0;
                        else
                            if (is_octave)
                                [p, h] = wilcoxon_test(S(i,:), S(j,:));
                            else
                                [p, h, ~] = signrank(dif, [], 'alpha', alpha ) ;  
                            end;
                            m1 = nanmean(S(i,:));
                            m2 = nanmean(S(j,:));
                            if (abs(m1 - m2) <= minimal_difference)
                                h = 0;
                            end;  
                        end;
                    case 'paired-prob'                    
                        dif = S(i,:)-S(j,:) ;
                        dif = dif(~isnan(dif)) ;
                        if (length(dif) < 5)
                            print_text('Warning: less than 5 samples comparing tracker %d and %d', i, j);
                            p = 1;
                            h = 0;
                        else
                            if (is_octave)
                                [p, h] = wilcoxon_test(S(i,:), S(j,:));
                            else
                                [p, h, ~] = signrank(dif, [], 'alpha', alpha ) ;
                            end;
                            e = sum(abs(dif) <= minimal_difference) / length(dif);
                            if (e > 0.95)
                                h = 0;
                            end;  
                        end;                        
                    case 'nonpaired'
                        if (is_octave)
                            [p,h] = u_test(S(i,:),S(j,:));
                        else
                            [p,h] = ranksum(S(i,:),S(j,:), 'alpha', alpha) ;
                        end;
                    otherwise 
                        error('Unknown type or pairing: %s', pairing) ;
                end
%             case 'Prob_better'                
%                 [ p, h ] = prob_of_better( S(i,:),S(j,:), 'min_difference', minimal_difference) ;             
        end
        H(i,j) = h ; H(j,i) = H(i,j) ;
        P(i,j) = p ; P(j,i) = P(i,j) ;        
    end
end


% ----------------------------------------------------------------------- %
% function [ p, h ] = prob_of_better( S1, S2, varargin )
%  
% min_difference = 0.1 ;
% for i = 1 :2: length(varargin)
%     switch varargin{i}
%         case 'min_difference'
%             min_difference = varargin{i+1} ;       
%         otherwise 
%             error(['Unknown switch ', varargin{i},'!']) ;
%     end
% end 
% 
% valid = ~isnan(S1) & ~isnan(S2) ;
% id_better_S1 = (S1 > S2) & (abs(S1-S2)>min_difference) & valid ;
% id_better_S2 = (S1 < S2) & (abs(S1-S2)>min_difference) & valid ;
%  
% id_better_S1 = id_better_S1(valid) ;
% id_better_S2 = id_better_S2(valid) ;
% 
% mu1 = mean(id_better_S1) ;
% mu2 = mean(id_better_S2) ;
%  
% p = max([mu1, mu2]) ;
% h = p > 0.5 ;
 



