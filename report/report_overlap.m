function [document, scores] = report_overlap(context, experiment, trackers, sequences, varargin)
% report_overlap Generate a report based on overlap thresholding methodology
%
% Performs overlap analysis and generates a report based on the results.
%
% Input:
% - context (structure): Report context structure.
% - experiment (struct): An experiment structure.
% - trackers (cell): An array of tracker structures.
% - sequences (cell): An array of sequence structures.
% - varargin[UseTags] (boolean): Analyze according to tags (otherwise according to sequences).
% - varargin[HideLegend] (boolean): Hide legend in plots.
%
% Output:
% - document (structure): Resulting document structure.
% - scores (struct): A scores structure.
%

usetags = get_global_variable('report_tags', true);
hidelegend = get_global_variable('report_lagend_hide', false);
orderingplot = get_global_variable('report_overlap_ordering', true);

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'usetags'
            usetags = varargin{i+1};
        case 'hidelegend'
            hidelegend = varargin{i+1};
        otherwise
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end


if ~strcmp(experiment.type, 'unsupervised')
   error('Overlap analysis only suitable for unsupervised experiments!');
end

document = document_create(context, 'overlap', 'title', 'Overlap');

trackers_hash = md5hash(strjoin((cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');
parameters_hash = md5hash(sprintf('%d', usetags));

tags = {};

if usetags && isfield(experiment, 'tags')
    tags = union(experiment.tags, {'all'});
    sequences_hash = md5hash(strjoin(tags, '-'), 'Char', 'hex');
else
    sequences_hash = md5hash(strjoin((cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');
end;

cache_identifier = sprintf('overlap_%s_%s_%s_%s', experiment.name, trackers_hash, sequences_hash, parameters_hash);

result = document_cache(context, cache_identifier, @analyze_overlap, experiment, trackers, ...
    sequences, 'tags', tags);

if usetags
    % When using tags we have inserted a separate one for this
    mask = strcmp('tag_all', result.selectors);

    average_curve = result.curves(:, mask, :);
    average_auc = result.auc(:, mask);

    % Now remove the 'all' tag from results
    tag_curve = result.curves(:, ~mask, :);
    tag_auc = result.auc(:, ~mask);

    selector_tags = cat(2, result.selectors(~mask), result.selectors(mask));
    
else
    
    average_curve = mean(result.curves, 2);
    average_auc = mean(result.auc, 2);  

    tag_curve = result.curves;
    tag_auc = result.auc;
    
    selector_tags = result.selectors;
    
end

scores.name = 'Overlap';
scores.values = average_auc;
scores.ids = {'auc'};
scores.names = {'AUC'};
scores.order = {'descending'};

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', 0);

print_text('Writing overlap table ...');

document.section('Experiment %s', experiment.name);

overlap_plot(document, sprintf('%s_average', experiment.name), ...
    sprintf('Experiment %s (average)', experiment.name), ...
    trackers, result.thresholds, ...
    reshape(average_curve, numel(trackers), numel(result.thresholds)), hidelegend);

table_data = highlight_best_rows(num2cell(cat(2, tag_auc, average_auc)), repmat({'descending'}, 1, size(tag_auc, 2) + 1));


document.table(table_data, 'columnLabels', selector_tags, 'rowLabels', tracker_labels, 'title', 'Overlap overview');

document.subsection('Detailed plots');

if orderingplot

    h = plot_ordering(trackers, cat(2, tag_auc, average_auc)', selector_tags, ...
        'scope', [0, 1], 'type', 'Overall overlap', 'legend', ~hidelegend);
    document.figure(h, sprintf('ordering_overlap_%s', experiment.name), ...
        'Orderings for overall overlap');

    close(h);
end;

for t = 1:size(tag_curve, 2)

    plot_title = sprintf('Overlap plot for tag %s in experiment %s', ...
        selector_tags{t}, experiment.name);
    plot_id = sprintf('overlap_%s_%s', experiment.name, selector_tags{t});

    overlap_plot(document, plot_id, plot_title, trackers, result.thresholds, ...
        reshape(tag_curve(:, t, :), numel(trackers), numel(result.thresholds)), ~hidelegend);

end;

document.write();

end

function overlap_plot(document, identifier, title, trackers, ...
    thresholds, curves, hidelegend)

    handle = plot_blank('Visible', false, 'Title', 'Overlap', 'Width', 6, 'Height', 6); hold on;

    phandles = zeros(numel(trackers), 1);

    for t = 1:size(curves, 1)
        phandles(t) = plot(thresholds, curves(t, :), 'Color', trackers{t}.style.color);
    end;

    labels = cellfun(@(x) x.label, trackers, 'UniformOutput', false);

    if ~hidelegend
        legend(phandles, labels);
    end;

    xlabel('Threshold');
    ylabel('Positive');
    xlim([0, 1]); 
    ylim([0, 1]);
    hold off;
    document.figure(handle, identifier, title);

    close(handle);
end
