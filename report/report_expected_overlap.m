function [document, scores] = report_expected_overlap(context, trackers, sequences, experiments, varargin)
% report_ranking Generate a report based on expected overlap
%
% Performs expected overlap analysis and generates a report based on the results.
%
% Input:
% - context (structure): Report context structure.
% - trackers (cell): An array of tracker structures.
% - sequences (cell): An array of sequence structures.
% - experiments (cell): An array of experiment structures.
% - varargin[UsePractical] (boolean): Use practical difference.
% - varargin[UseLabels] (boolean): Rank according to labels (otherwise rank according to sequences).
% - varargin[HideLegend] (boolean): Hide legend in plots.
% - varargin[RangeThreshold] (double): Threshold used for range estimation.
%
% Output:
% - document (structure): Resulting document structure.
% - scores (matrix): Averaged overlaps for the entire tracker set.
%

uselabels = get_global_variable('report_labels', true);
usepractical = get_global_variable('report_ranking_practical', true);
hidelegend = get_global_variable('report_legend_hide', false);
range_threshold = 0.5;

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'usepractical'
            usepractical = varargin{i+1};
        case 'uselabels'
            uselabels = varargin{i+1};
        case 'hidelegend'
            hidelegend = varargin{i+1};
        case 'rangethreshold'
            range_threshold = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']);
    end
end 

document = create_document(context, 'expected_overlap', 'title', 'Expected overlap analysis');

results = cell(length(experiments), 1);
scores = nan(length(experiments), length(trackers));

trackers_hash = md5hash(strjoin((cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');
parameters_hash = md5hash(sprintf('%d-%d', uselabels, usepractical));
sequences_hash = md5hash(strjoin((cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');

for e = 1:length(experiments)

    cache_identifier = sprintf('expected_overlap_%s_%s_%s_%s', experiments{e}.name, trackers_hash, sequences_hash, parameters_hash);
    
    result = report_cache(context, cache_identifier, ...
        @analyze_expected_overlap, experiments{e}, trackers, ...
        sequences, 'uselabels', uselabels, 'usepractical', usepractical);
    results{e} = result;
  
    [~, peak, low, high] = estimate_evaluation_interval(sequences, range_threshold);
    
    for t = 1:numel(trackers)
        scores(e, t) = mean(results{e}.curves{t});
    end;
    
    document.section('Experiment %s', experiments{e}.name);
    
    plot_title = sprintf('Expected overlap curvers for %s', experiments{e}.name);
    plot_id = sprintf('expected_overlap_curves_%s', experiments{e}.name);

    handle = generate_plot('Visible', false, ...
        'Title', plot_title, 'Width', 8);
    
    hold on;

    plot([peak, peak], [1, 0], '--', 'Color', [0.6, 0.6, 0.6]);
    plot([low, low], [1, 0], ':', 'Color', [0.6, 0.6, 0.6]);
    plot([high, high], [1, 0], ':', 'Color', [0.6, 0.6, 0.6]);
    
    phandles = zeros(numel(trackers), 1);
    for t = 1:numel(trackers)
        phandles(t) = plot(results{e}.lengths, results{e}.curves{t}, 'Color', trackers{t}.style.color);
    end;
    
    if ~hidelegend
        legend(phandles, cellfun(@(x) x.label, trackers, 'UniformOutput', false), 'Location', 'NorthWestOutside', 'interpreter', 'none'); 
    end;

    xlabel('Sequence length');
    ylabel('Expected overlap');
    xlim([1, max(results{e}.lengths(:))]); 
    ylim([0, 1]);

    hold off;
    
    document.figure(handle, plot_id, plot_title);
    
    close(handle);
    
    plot_title = sprintf('Expected overlap scores for %s', experiments{e}.name);
    plot_id = sprintf('expected_overlaps_%s', experiments{e}.name);

    handle = generate_plot('Visible', false, ...
        'Title', plot_title, 'Grid', false);
    
    hold on;
    
    weights = ones(numel(results{e}.lengths(:)), 1);
    weights(:) = 0;
    weights(low:high) = 1;

    experiment_scores = cellfun(@(x) sum(x(:) .* weights) / sum(weights), results{e}.curves, 'UniformOutput', true);
    experiment_practical = cellfun(@(x) sum(x(:) .* weights) / sum(weights), results{e}.practical, 'UniformOutput', true);

    [ordered_scores, order] = sort(experiment_scores, 'descend');

    phandles = zeros(numel(trackers), 1);
    for t = 1:numel(order)
        tracker = trackers{order(t)};
        plot([t, t], [0, ordered_scores(t)], ':', 'Color', [0.8, 0.8, 0.8]);
        if experiment_practical(t) > 0.001
            draw_interval(t, ordered_scores(t), experiment_practical(t), experiment_practical(t), ':', 'Color', [0.6, 0.6, 0.6]);            
        end
        phandles(t) = plot(t, ordered_scores(t), tracker.style.symbol, 'Color', tracker.style.color, 'MarkerSize', 10, 'LineWidth', tracker.style.width);
    end;

    if ~hidelegend
        legend(phandles, cellfun(@(x) x.label, trackers(order), 'UniformOutput', false), 'Location', 'NorthWestOutside', 'interpreter', 'none'); 
    end;
    
    xlabel('Order');
    ylabel('Average expected overlap');
    xlim([1, numel(trackers)]); 
    set(gca, 'XTick', 1:5:numel(trackers));
    set(gca, 'XDir', 'Reverse');
    ylim([0, 1]);
    
    hold off;
    
    document.figure(handle, plot_id, plot_title);
    
    close(handle);
    
    scores(e, :) = experiment_scores;
    
    document.text('Scores calculated as an average over interval %d to %d', low, high);
    
end;

document.write();

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

function draw_interval(x, y, low, high, varargin) 
    plot([x - 0.1, x + 0.1], [y, y] - low, varargin{:});
    plot([x - 0.1, x + 0.1], [y, y] + high, varargin{:});
    plot([x, x], [y - low, y + high], varargin{:});
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
