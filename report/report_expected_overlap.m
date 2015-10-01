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
%
% Output:
% - document (structure): Resulting document structure.
% - scores (matrix): Averaged overlaps for the entire tracker set.
%

uselabels = get_global_variable('report_labels', true);
usepractical = get_global_variable('report_ranking_practical', true);
hidelegend = get_global_variable('report_legend_hide', false);

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'usepractical'
            usepractical = varargin{i+1};
        case 'uselabels'
            uselabels = varargin{i+1};
        case 'hidelegend'
            hidelegend = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
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
  
    for t = 1:numel(trackers)
        scores(e, t) = mean(results{e}.curves{t});
    end;
    
    document.section('Experiment %s', experiments{e}.name);
    
    plot_title = sprintf('Expected overlap curvers for %s', experiments{e}.name);
    plot_id = sprintf('expected_overlap_curves_%s', experiments{e}.name);

    handle = generate_plot('Visible', false, ...
        'Title', plot_title, 'Width', 8);
    
    hold on;

    for t = 1:numel(trackers)
        plot(results{e}.lengths, results{e}.curves{t}, 'Color', trackers{t}.style.color);
    end;
    
    if ~hidelegend
        legend(cellfun(@(x) x.label, trackers, 'UniformOutput', false), 'Location', 'NorthWestOutside', 'interpreter', 'none'); 
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
        'Title', plot_title);
    
    hold on;
    
    weights = ones(numel(results{e}.lengths(:)), 1);
    
    experiment_scores = cellfun(@(x) sum(x(:) .* weights) / sum(weights), results{e}.curves, 'UniformOutput', true);

    [ordered_scores, order] = sort(experiment_scores, 'descend');

    for t = 1:numel(order)
        tracker = trackers{order(t)};
        plot(t, ordered_scores(t), tracker.style.symbol, 'Color', tracker.style.color, 'MarkerSize', 10, 'LineWidth', tracker.style.width);
    end;

    if ~hidelegend
        legend(cellfun(@(x) x.label, trackers(order), 'UniformOutput', false), 'Location', 'NorthWestOutside', 'interpreter', 'none'); 
    end;
    
    xlabel('Order');
    ylabel('Average expected overlap');
    xlim([1, numel(trackers)]); 
    set(gca, 'XTick', 1:numel(trackers));
    set(gca, 'XDir', 'Reverse');
    ylim([0, 1]);
    
    hold off;
    
    document.figure(handle, plot_id, plot_title);
    
    close(handle);
    
    scores(e, :) = experiment_scores;
    
end;

document.write();

end
