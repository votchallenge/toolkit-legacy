function [additional_accuracy, additional_robustness, additional_available] = ...
    compare_additional_trackers(experiment, additional_trackers, additional_aspects, available, accuracy, robustness, sequences)

N_trackers = length(additional_trackers);
N_aspects = length(additional_aspects);

% initialize accuracy outputs
additional_accuracy.mu = zeros(N_aspects, N_trackers);
additional_accuracy.std = zeros(N_aspects, N_trackers);
additional_accuracy.ranks = zeros(N_aspects, N_trackers);

% initialize robustness outputs
additional_robustness.mu = zeros(N_aspects, N_trackers);
additional_robustness.std = zeros(N_aspects, N_trackers);
additional_robustness.ranks = zeros(N_aspects, N_trackers);

% initialize available output
additional_available = true(N_trackers, 1);

print_indent(1);

% load additional tracker data
for a = 1:N_aspects    
    
    print_text('Processing aspect %s ...', additional_aspects{a}.name);

    print_indent(1);

    for t = 1:N_trackers
        print_text('Processing tracker %s ...', additional_trackers{t}.identifier);

        [A, R] = additional_aspects{a}.aggregate(experiment, additional_trackers{t}, sequences); 

        if isempty(A) 
            additional_available(t) = false;
        end

        valid_frames = ~isnan(A);

        additional_accuracy.mu(a, t) = mean(A(valid_frames));
        additional_accuracy.std(a, t) = std(A(valid_frames));

        additional_robustness.mu(a, t) = mean(R);
        additional_robustness.std(a, t) = std(R);                
    end        
    
    print_indent(-1);        
    
end
print_indent(-1);

print_text('Comparing additional trackers with regular ones');

% Compare trackers with regular ones
for t = 1:N_trackers
    tracker_acc_results = repmat(additional_accuracy.mu(:, t), 1, sum(available));
    tracker_rob_results = repmat(additional_robustness.mu(:, t), 1, sum(available));
    
    % Compute differences matrixes
    diff_acc_mat = accuracy.mu - tracker_acc_results;            
    diff_rob_mat = tracker_rob_results - robustness.mu;

    diff_acc_better = diff_acc_mat;
    diff_acc_better(diff_acc_better < 0) = nan;            
    diff_acc_worse = diff_acc_mat;
    diff_acc_worse(diff_acc_worse >= 0) = nan;

    diff_rob_better = diff_rob_mat;
    diff_rob_better(diff_rob_better < 0) = nan;            
    diff_rob_worse = diff_rob_mat;
    diff_rob_worse(diff_rob_worse >= 0) = nan;

    for a = 1:N_aspects
        % Accuracy
        [val, pos] = min(diff_acc_better(a, :));                
        [val2, pos2] = max(diff_acc_worse(a, :));

        if isnan(val)
            % Additional tracker is better than every other
            rank_diff = accuracy.ranks(a, pos2) * abs(val2);
            additional_accuracy.ranks(a, t) = ...
                min(max(accuracy.ranks(a, pos2) - rank_diff, 1), length(available));

        elseif isnan(val2)
            % Additional tracker is worse than every other
            rank_diff = accuracy.ranks(a, pos) * val;
            additional_accuracy.ranks(a, t) = ...
                min(max(accuracy.ranks(a, pos) + rank_diff, 1), length(available));
        else                
            percentage = abs(val2)/(val + abs(val2));
            rank_diff = accuracy.ranks(a, pos2) - accuracy.ranks(a, pos);
            additional_accuracy.ranks(a, t) = ...
                min(max(accuracy.ranks(a, pos) + (rank_diff*percentage), 1), length(available));  
        end

        % Robustness
        [val, pos] = min(diff_rob_better(a, :));
        [val2, pos2] = max(diff_rob_worse(a, :));

        if val == 0
            % Regular tracker with same robustness found
            additional_robustness.ranks(a, t) = robustness.ranks(a, pos);
        elseif isnan(val)
            % Additional tracker is better than every other
            rank_diff = robustness.ranks(a, pos2) * abs(val2);
            additional_robustness.ranks(a, t) = ...
                min(max(robustness.ranks(a, pos2) - rank_diff, 1), length(available));
        elseif isnan(val2)
            % Additional tracker is worse than every other
            rank_diff = robustness.ranks(a, pos) * val;
            additional_robustness.ranks(a, t) = ...
                min(max(robustness.ranks(a, pos) + rank_diff, 1), length(available));
        else
            percentage = abs(val2)/(val + abs(val2));
            rank_diff = robustness.ranks(a, pos2) - robustness.ranks(a, pos);
            additional_robustness.ranks(a, t) = ...
                min(max(robustness.ranks(a, pos) + (rank_diff*percentage), 1), length(available));
        end                
    end                   
end
additional_accuracy.average_ranks = mean(additional_accuracy.ranks, 1);
additional_robustness.average_ranks = mean(additional_robustness.ranks, 1);