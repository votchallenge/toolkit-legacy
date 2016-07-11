function [result] = analyze_average_expected_overlap(experiment, trackers, sequences, varargin)

range_threshold = 0.5;

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'labels'
            labels = varargin{i+1};
        case 'rangethreshold'
            range_threshold = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']);
    end
end 

experiment_sequences = convert_sequences(sequences, experiment.converter);

expected_overlap = analyze_expected_overlap(experiment, trackers, sequences, 'labels', labels);

[~, peak, low, high] = estimate_evaluation_interval(experiment_sequences, range_threshold);

weights = ones(numel(expected_overlap.lengths(:)), 1);
weights(:) = 0;
weights(low:high) = 1;

result.scores = zeros(numel(trackers), numel(labels));
result.low = low;
result.high = high;
result.peak = peak;

for p = 1:numel(labels)
    valid =  cellfun(@(x) numel(x) > 0, expected_overlap.curves, 'UniformOutput', true)';
    result.scores(valid, p) = cellfun(@(x) sum(x(~isnan(x(:, p)), p) .* weights(~isnan(x(:, p)))) / sum(weights(~isnan(x(:, p)))), expected_overlap.curves(valid), 'UniformOutput', true);
end

end

function [gmm, peak, low, high] = estimate_evaluation_interval(sequences, threshold)

sequence_lengths = cellfun(@(x) x.length, sequences, 'UniformOutput', true);
model = gmm_estimate(sequence_lengths); % estimate the pdf by KDE
 
% tabulate the GMM from zero to max length
x = 1:max(sequence_lengths) ;
p = gmm_evaluate(model, x) ;
p = p / sum(p); 
gmm.x = x;
gmm.p = p;

[low, high] = find_range(p, threshold) ;
[~, peak] = max(p);

end

function [low, high] = find_range(p, density)

% find maximum on the KDE
[~, x_max] = max(p);
low = x_max ;
high = x_max ;

for i = 0:length(p)
    x_lo_tmp = low - 1 ;
    x_hi_tmp = high + 1 ;
    
    sw_lo = 0 ; sw_hi = 0 ; % boundary indicator
    % clip
    if x_lo_tmp <= 0 , x_lo_tmp = 1 ;  sw_lo = 1 ; end
    if x_hi_tmp >= length(p), x_hi_tmp = length(p); sw_hi = 1; end
    
    % increase left or right boundary
    if sw_lo==1 && sw_hi==1
        low = x_lo_tmp ;
        high = x_hi_tmp ;
        break ;
    elseif sw_lo==0 && sw_hi==0
        if p(x_lo_tmp) > p(x_hi_tmp)
            low = x_lo_tmp ;
        else
            high = x_hi_tmp ;
        end
    else
        if sw_lo==0, low = x_lo_tmp ; else high = x_hi_tmp ; end
    end
    
    % check the integral under the range
    s_p = sum(p(low:high)) ;
    if s_p >= density
        return ;
    end
end            

end
