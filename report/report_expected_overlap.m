function [document, scores] = report_expected_overlap(context, experiment, trackers, sequences, varargin)
% report_ranking Generate a report based on expected overlap
%
% Performs expected overlap analysis and generates a report based on the results.
%
% Input:
% - context (structure): Report context structure.
% - experiments (struct): An experiment structure.
% - trackers (cell): An array of tracker structures.
% - sequences (cell): An array of sequence structures.
% - varargin[UsePractical] (boolean): Use practical difference.
% - varargin[UseTags] (boolean): Rank according to tags (otherwise rank according to sequences).
% - varargin[HideLegend] (boolean): Hide legend in plots.
%
% Output:
% - document (structure): Resulting document structure.
% - scores (matrix): Averaged EAO scores.

usetags = false;
usepractical = false;
hidelegend = get_global_variable('report_legend_hide', false);

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'usepractical'
            usepractical = varargin{i+1};
        case 'usetags'
            usetags = varargin{i+1};
        case 'hidelegend'
            hidelegend = varargin{i+1};
        otherwise
            error(['Unknown switch ', varargin{i}, '!']);
    end
end

document = document_create(context, 'expected_overlap', 'title', 'Expected overlap analysis');

if ~strcmp(experiment.type, 'supervised') && ~strcmp(experiment.type, 'realtime')
   error('EAO analysis only suitable for supervised experiments!');
end

trackers_hash = md5hash(strjoin((cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');
parameters_hash = md5hash(sprintf('%d-%d', usetags, usepractical));
sequences_hash = md5hash(strjoin((cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', 0);

cache_identifier_curves = sprintf('expected_overlap_%s_%s_%s_%s', experiment.name, ...
    trackers_hash, sequences_hash, parameters_hash);

cache_identifier_scores = sprintf('average_expected_overlap_%s_%s_%s_%s', experiment.name, ...
    trackers_hash, sequences_hash, parameters_hash);

if usetags
    tags = cat(2, {'all'}, experiment.tags);
else
    tags = {'all'};
end;

result_curves = document_cache(context, cache_identifier_curves, ...
    @analyze_expected_overlap, experiment, trackers, ...
    sequences, 'Tags', tags);

result_scores = document_cache(context, cache_identifier_scores, ...
    @analyze_average_expected_overlap, experiment, trackers, ...
    sequences, 'Tags', tags);

document.section('Experiment %s', experiment.name);

for p = 1:numel(tags)

    valid =  cellfun(@(x) numel(x) > 0, result_curves.curves, 'UniformOutput', true)';

    if p == 1
        plot_title = sprintf('Expected overlap curves for %s', experiment.name);
        plot_id = sprintf('expected_overlap_curves_%s', experiment.name);
    else
        plot_title = sprintf('Expected overlap curves for %s (%s)', experiment.name, tags{p});
        plot_id = sprintf('expected_overlap_curves_%s_%s', experiment.name, tags{p});
        document.subsection('Tag %s', tags{p});
    end;

    handle = plot_blank('Visible', false, ...
        'Title', plot_title, 'Width', 8);

    hold on;

    plot([result_scores.peak, result_scores.peak], [1, 0], '--', 'Color', [0.6, 0.6, 0.6]);
    plot([result_scores.low, result_scores.low], [1, 0], ':', 'Color', [0.6, 0.6, 0.6]);
    plot([result_scores.high, result_scores.high], [1, 0], ':', 'Color', [0.6, 0.6, 0.6]);

    phandles = zeros(numel(trackers), 1);
    for t = find(valid)
        phandles(t) = plot(result_curves.lengths, result_curves.curves{t}(:, p), 'Color', trackers{t}.style.color);
    end;

    if ~hidelegend
        legend(phandles(valid), cellfun(@(x) x.label, trackers(valid), 'UniformOutput', false), 'Location', 'NorthWestOutside', 'interpreter', 'none');
    end;

    xlabel('Sequence length');
    ylabel('Expected overlap');
    xlim([1, max(result_curves.lengths(:))]);
    ylim([0, 1]);

    hold off;

    document.figure(handle, plot_id, plot_title);

    close(handle);

    plot_title = sprintf('Expected overlap scores for %s', experiment.name);
    plot_id = sprintf('expected_overlaps_%s_%s', experiment.name, tags{p});

    handle = plot_blank('Visible', false, ...
        'Title', plot_title, 'Grid', false);

    hold on;

    [ordered_scores, order] = sort(result_scores.scores(:, p), 'descend');

    phandles = zeros(numel(trackers), 1);
    for t = 1:numel(order)
        tracker = trackers{order(t)};
        plot([t, t], [0, ordered_scores(t)], ':', 'Color', [0.8, 0.8, 0.8]);
        phandles(t) = plot(t, ordered_scores(t), tracker.style.symbol, 'Color', tracker.style.color, 'MarkerSize', 10, 'LineWidth', tracker.style.width);
    end;

    if ~hidelegend
        legend(phandles, cellfun(@(x) x.label, trackers(order), 'UniformOutput', false), 'Location', 'NorthWestOutside', 'interpreter', 'none');
    end;

    xlabel('Order');
    ylabel('Average expected overlap');
    xlim([0.9, numel(trackers) + 0.1]);
    set(gca, 'XTick', 1:max(1, ceil(log(numel(trackers)))):numel(trackers));
    set(gca, 'XDir', 'Reverse');
    ylim([0, 1]);

    hold off;

    document.figure(handle, plot_id, plot_title);

    close(handle);
end;

document.subsection('Overview');
document.text('Scores calculated as an average over interval %d to %d', result_scores.low, result_scores.high);

if usetags && numel(tags) > 1

    h = plot_ordering(trackers, result_scores.scores(:, 2:end)' , tags(2:end), ...
        'flip', false, 'legend', ~hidelegend, 'scope', [0, 1]);
        document.figure(h, sprintf('ordering_expected_overlap_%s', experiment.name), ...
        'Ordering plot for expected overlap');

    close(h);

end

[~, order] = sort(result_scores.scores(:, 1), 'descend');

scores.name = 'EAO';
scores.ids = {'eao'};
scores.names = {'EAO'};
scores.order = {'descending'};
scores.values = result_scores.scores(:, 1);

tabledata = num2cell(result_scores.scores);
tabledata = highlight_best_rows(tabledata, repmat({'descending'}, 1, numel(tags)));

document.table(tabledata(order, :), 'columnLabels', tags, 'rowLabels', tracker_labels(order));

document.write();

end

% function draw_interval(x, y, low, high, varargin)
%     plot([x - 0.1, x + 0.1], [y, y] - low, varargin{:});
%     plot([x - 0.1, x + 0.1], [y, y] + high, varargin{:});
%     plot([x, x], [y - low, y + high], varargin{:});
% end

