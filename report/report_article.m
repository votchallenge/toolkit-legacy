function [document] = report_article(context, experiments, trackers, sequences, varargin)

arplot = true;
permutationplot = false;
ratio = 0.5;
spotlight = [];
master_legend = true;

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'arplot'
            arplot = varargin{i+1};
        case 'permutationplot'
            permutationplot = varargin{i+1};
        case 'combineweight'
            ratio = varargin{i+1};
        case 'spotlight'
            spotlight = varargin{i+1};
        case 'masterlegend'
            master_legend = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end 


document = create_document(context, 'article', 'title', 'VOT article report');

print_text('Generating article report'); print_indent(1);

if master_legend

    document.chapter('Trackers legend');

    % Using heuristic to generate tracker legend, 8 per row seems ok for
    % paper
    rows = ceil(numel(trackers) / 8);
    columns = ceil(numel(trackers) / rows);

    lh = generate_trackers_legend(trackers, 'visible', false, 'columns', columns, 'rows', rows);

    document.figure(lh, 'tracker_legend', 'Tracker legend');

    close(lh);

end;

print_text('Ranking report ...'); print_indent(1);

[ranking_document, ranks] = report_ranking(context, trackers, sequences, experiments, ...
    'uselabels', false, 'usepractical', true, 'tableformat', 'fragmented', ...
    'tableorientation', 'selectors', ...
    'arplot', arplot, 'permutationplot', permutationplot, 'hidelegend', master_legend);

combined_ranks = squeeze(mean(ranks, 1));

overall_ranks = ratio * combined_ranks(:, 1) + (1 - ratio) * combined_ranks(:, 2);
[~, order] = sort(overall_ranks,'ascend')  ;

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', 0);

column_labels = cell(2, 2 * numel(experiments) + 3);

ranking_labels = {'Acc. Rank', 'Rob. Rank'};
column_labels(1, :) = repmat({struct()}, 1, size(column_labels, 2));
column_labels(1, 1:2:end-4) = cellfun(@(x) struct('text', x.name, 'columns', 2), experiments,'UniformOutput',false);
column_labels{1, end-3} = struct('text', '', 'columns', 4);
column_labels(2, :) = [ranking_labels(repmat(1:length(ranking_labels), 1, numel(experiments) + 1)), {'Rank'}];

experiments_ranking_data = zeros(2 * numel(experiments), numel(trackers));
experiments_ranking_data(1:2:end) = ranks(:, :, 1);
experiments_ranking_data(2:2:end) = ranks(:, :, 2);
experiments_ranking_data = num2cell(experiments_ranking_data);

overall_ranking_data = num2cell(cat(2, combined_ranks, overall_ranks)');

tabledata = cat(1, experiments_ranking_data, overall_ranking_data)';

ordering = repmat({'ascending'}, 1, numel(experiments) * 2 + 3);
tabledata = highlight_best_rows(tabledata, ordering);

document.chapter('Ranking');

document.table(tabledata(order, :), 'columnLabels', column_labels, 'rowLabels', tracker_labels(order));

document.link(ranking_document.url, 'Detailed ranking results');

if ~isempty(spotlight)
    print_text('WARNING: The spotlight feature is not complete and does not work as planned.');

    highlight_index = find_tracker(trackers, spotlight);
    
    if ~isempty(highlight_index)

        document.chapter('Hightlights for tracker %s');

        [spotlight_document, highlights] = report_ranking_spotlight(context, trackers, sequences, experiments, spotlight,  'uselabels', false, 'usepractical', true);

        document.link(spotlight_document.url, 'Detailed spotlight results');

        % TODO: hightlight for tracker
    end;

end;
    
document.write();
