function [document] = report_article(context, experiments, trackers, sequences, varargin)
% report_article Generate an article friendly report
%
% Generate a per-sequence A-R ranking analysis report as well as some additional analysis that is
% more suitable for interpretation in articles.
%
% Input:
% - context (structure): Report context structure.
% - trackers (cell): An array of tracker structures.
% - sequences (cell): An array of sequence structures.
% - experiments (cell): An array of experiment structures.
% - varargin[Spotlight] (string): Identifier of a tracker that is in the spotlight of the analysis.
% - varargin[MasterLegend] (boolean): Use a single master legend instead of including it .
%
% Output:
% - document (structure): Resulting document structure.
%

spotlight = [];
master_legend = true;
methodology = 'vot2015';

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'spotlight'
            spotlight = varargin{i+1};
        case 'masterlegend'
            master_legend = varargin{i+1};
        case 'methodology'
            methodology = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end 

if numel(trackers) < 2
    error('Ranking analysis requires two or more trackers.');
end;

switch lower(methodology)
    case {'vot2013', 'vot2014'}
        ranking_adaptation = 'mean';
    case 'vot2015'
        ranking_adaptation = 'best';
    otherwise 
        error(['Unknown methodology ', methodology, '!']) ;
end

document = create_document(context, 'article', 'title', 'VOT article report');

print_text('Generating article report'); print_indent(1);

if master_legend

    document.section('Trackers legend');

    % Using heuristic to generate tracker legend, 8 per row seems ok for
    % paper
    rows = ceil(numel(trackers) / 8);
    columns = ceil(numel(trackers) / rows);

    lh = generate_trackers_legend(trackers, 'visible', false, 'columns', columns, 'rows', rows);

    document.figure(lh, 'tracker_legend', 'Tracker legend');

    close(lh);

end;

print_text('Ranking report ...'); print_indent(1);

print_indent(1);

[ranking_document, ranks_scores] = report_ranking(context, trackers, sequences, experiments, ...
    'uselabels', false, 'usepractical', true, 'adaptation', ranking_adaptation, ...
    'hidelegend', master_legend);

print_indent(-1);

print_indent(1);

[expected_overlap_document, expected_overlap_scores] = report_expected_overlap(context, trackers, sequences, experiments, ...
    'uselabels', true, 'usepractical', true);

print_indent(-1);

switch lower(methodology)
    case {'vot2013', 'vot2014'}
        scores = ranks_scores;
        score_labels = {'Acc. Rank', 'Rob. Rank'};
        score_sorting_partial = {'ascending', 'ascending'};
        score_sorting_overall = 'ascending';
        sort_direction = 'ascend';
        score_weights = [0.5, 0.5];
        score_format = '%.2f';
    case 'vot2015'
        scores = expected_overlap_scores;
        score_labels = {'Expected overlap'};
        score_sorting_partial = {'descending'};
        score_sorting_overall = 'descending';
        sort_direction = 'descend';
        score_weights = 1;
        score_format = '%.4f';
    otherwise 
        error(['Unknown methodology ', methodology, '!']) ;
end

N_scores = numel(score_labels);
combined_scores = squeeze(mean(scores, 1));

overall_scores = bsxfun(@prod, combined_scores, score_weights) ./ sum(score_weights);
[~, order] = sort(overall_scores, sort_direction);

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', 0);

column_labels = cell(2, N_scores * numel(experiments) + 1);

column_labels(1, :) = repmat({struct()}, 1, size(column_labels, 2));
column_labels(1, 1:N_scores:end-1) = cellfun(@(x) struct('text', x.name, 'columns', N_scores), experiments,'UniformOutput',false);
column_labels(2, :) = [score_labels(repmat(1:length(score_labels), 1, numel(experiments))), {'Overall'}];

experiments_ranking_data = zeros(N_scores * numel(experiments), numel(trackers));
for i = 1:N_scores
    experiments_ranking_data(1:i:end) = scores(:, :, i);
end
experiments_ranking_data = num2cell(experiments_ranking_data);
overall_ranking_data = num2cell(overall_scores);

tabledata = cat(1, experiments_ranking_data, overall_ranking_data)';
tabledata = highlight_best_rows(tabledata, cat(2, repmat(score_sorting_partial, 1, numel(experiments)), {score_sorting_overall}));

document.section('Ranking');

document.table(tabledata(order, :), 'columnLabels', column_labels, 'rowLabels', tracker_labels(order), 'format', score_format);

document.link(ranking_document.url, 'Detailed ranking results');

document.link(expected_overlap_document.url, 'Detailed expected overlap results');

if ~isempty(spotlight)
    print_text('WARNING: The spotlight feature is not complete and does not work as planned.');

    highlight_index = find_tracker(trackers, spotlight);
    
    if ~isempty(highlight_index)

        document.section('Hightlights for tracker %s');

        spotlight_document = report_ranking_spotlight(context, trackers, sequences, experiments, spotlight, 'usepractical', true);

        document.link(spotlight_document.url, 'Detailed spotlight results');

        % TODO: hightlights for tracker
    end;

end;
    
document.write();
