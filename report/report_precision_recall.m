function [document, scores] = report_precision_recall(context, experiment, trackers, sequences, varargin)
% report_overlap Generate a report using tracking precision recall methodology
%
% Performs tracking precision-recall analysis and generates a report based on the results.
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
resolution = 100;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'usetags'
            usetags = varargin{i+1};
        case 'resolutuion'
            resolution = varargin{i+1};
        case 'hidelegend'
            hidelegend = varargin{i+1};
        otherwise
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end


if ~strcmp(experiment.type, 'unsupervised')
   error('Tracking precision-recall analysis only suitable for unsupervised experiments!');
end

document = document_create(context, 'tpr', 'title', 'Tracking precision recall');

trackers_hash = md5hash(strjoin((cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');
parameters_hash = md5hash(sprintf('%d%d', usetags, resolution));

tags = {};

if isempty(experiment.tags)
    usetags = false;
end;

if usetags && isfield(experiment, 'tags')
    tags = union(experiment.tags, {'all'});
    sequences_hash = md5hash(strjoin(tags, '-'), 'Char', 'hex');
else
    sequences_hash = md5hash(strjoin((cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');
end;

cache_identifier = sprintf('tpr_%s_%s_%s_%s', experiment.name, trackers_hash, sequences_hash, parameters_hash);

result = document_cache(context, cache_identifier, @analyze_precision_recall, experiment, trackers, ...
    sequences, 'Tags', tags, 'Resolution', resolution);

if usetags
    % When using tags we have inserted a separate one for this
    mask = strcmp('tag_all', result.selectors);

    average_curve = result.curves(:, mask);
    average_measures = result.measures(:, mask);

    % Now remove the 'all' tag from results
    tag_curve = result.curves(:, ~mask);
    tag_measures = result.measures(:, ~mask);

    selector_tags = cat(2, result.selectors(~mask), result.selectors(mask));
    
else
    
    average_curve = cell(numel(trackers), 1);
    average_measures = zeros(numel(trackers), 3);
    
    for t = 1:numel(trackers)
        average_curve{t} = mean(cat(3, result.curves{t, :}), 3);
        f = 2 * (average_curve{t}(:, 1) .* average_curve{t}(:, 2)) ./ (average_curve{t}(:, 1) + average_curve{t}(:, 2));
        [average_measures(t, 1), idx] = max(f);
        average_measures(t, 2) = average_curve{t}(idx, 1);
        average_measures(t, 3) = average_curve{t}(idx, 2);
    end;
        
    tag_curve = result.curves;
    tag_measures = result.measures;
    
    selector_tags = result.selectors;
    
end

scores.name = 'TPR';
scores.values = average_measures;
scores.ids = {'f', 'tp', 'tr'};
scores.names = {'F', 'TP', 'TR'};
scores.order = {'descending', 'descending', 'descending'};

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', 0);

print_text('Writing tracking precision-recall table ...');

document.section('Experiment %s', experiment.name);

pr_plot(document, sprintf('%s_average', experiment.name), ...
    sprintf('Experiment %s (average)', experiment.name), ...
    trackers, average_curve, hidelegend);

table_data = highlight_best_rows(num2cell(cat(2, tag_measures(:, : , 1), average_measures(:, 1))), repmat({'descending'}, 1, size(tag_measures, 2) + 1));

document.table(table_data, 'columnLabels', selector_tags, 'rowLabels', tracker_labels, 'title', 'Tracking precision-recall overview');

document.subsection('Detailed plots');

for t = 1:size(tag_curve, 2)

    plot_title = sprintf('Tracking precision-recall plot for tag %s in experiment %s', ...
        selector_tags{t}, experiment.name);
    plot_id = sprintf('overlap_%s_%s', experiment.name, selector_tags{t});

    pr_plot(document, plot_id, plot_title, trackers, tag_curve(:, t), ~hidelegend);

end;

document.write();

end

function pr_plot(document, identifier, title, trackers, curves, hidelegend)

    handle = plot_blank('Visible', false, 'Title', 'Overlap', 'Width', 6, 'Height', 6); hold on;

    phandles = zeros(numel(trackers), 1);

    for t = 1:numel(curves)
        phandles(t) = plot(curves{t}(:, 2), curves{t}(:, 1), 'Color', trackers{t}.style.color);
    end;

    labels = cellfun(@(x) x.label, trackers, 'UniformOutput', false);

    if ~hidelegend
        legend(phandles, labels);
    end;

    xlabel('Tracking recall');
    ylabel('Tracking precision');
    xlim([0, 1]); 
    ylim([0, 1]);
    hold off;
    document.figure(handle, identifier, title);

    close(handle);
end
