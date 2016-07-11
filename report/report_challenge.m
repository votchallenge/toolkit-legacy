function [document] = report_challenge(context, experiments, trackers, sequences, varargin)
% report_challenge Generate an official challenge report
%
% Generate a per-label A-R ranking analysis report as well as some additional analysis that is
% used to obtain challenge results.
%
% Input:
% - context (structure): Report context structure.
% - trackers (cell): An array of tracker structures.
% - sequences (cell): An array of sequence structures.
% - experiments (cell): An array of experiment structures.
% - varargin[Methodology] (string): The methodology to use for final ranking.
% - varargin[Speed] (boolean): Generate speed report.
% - varargin[Failures] (boolean): Generate failures report.
% - varargin[Difficulty] (boolean): Generate difficulty report.
% - varargin[MasterLegend] (boolean): Use a single master legend instead of including it .
%
% Output:
% - document (structure): Resulting document structure.
%

implementation = true;
failures = true;
difficulty = true;
master_legend = true;
methodology = 'vot2015';

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'implementation'
            implementation = varargin{i+1};
        case 'failures'
            failures = varargin{i+1}; 
        case 'difficulty'
            difficulty = varargin{i+1};             
        case 'methodology'
            methodology = varargin{i+1};
        case 'masterlegend'
            master_legend = varargin{i+1};            
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end

if numel(trackers) < 2
    error('Challenge analysis requires two or more trackers.');
end;

switch lower(methodology)
    case {'vot2013', 'vot2014'}
        ranking_adaptation = 'mean';
    case {'vot2015', 'vot2016'}
        ranking_adaptation = 'best';
    otherwise 
        error(['Unknown methodology ', methodology, '!']) ;
end


document = create_document(context, 'challenge', 'title', 'VOT competition report');

print_text('Generating competition report'); print_indent(1);

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

print_text('Ranking report ...');print_indent(1);

[ranking_document, ranks_scores] = report_ranking(context, trackers, sequences, experiments, ...
    'uselabels', true, 'usepractical', true, ...
    'hidelegend', master_legend, 'adaptation', ranking_adaptation, 'average', 'weighted_mean');

print_indent(-1);

print_text('Expected overlap report ...'); print_indent(1);

[expected_overlap_document, expected_overlap_scores] = report_expected_overlap(context, trackers, sequences, experiments, ...
    'uselabels', true, 'usepractical', false, 'hidelegend', master_legend);

print_indent(-1);

document.section('Index');

document.link(ranking_document.url, 'Ranking analysis');

document.link(expected_overlap_document.url, 'Expected overlap analysis');

if implementation

    print_text('Implementation report ...'); print_indent(1);
    
    implementation_document = report_implementation(context, trackers, sequences, experiments);

    print_indent(-1);

    document.link(implementation_document.url, 'Implementation analysis');
end

if failures

    print_text('Failures report ...'); print_indent(1);

    failures_document = report_failures(context, trackers, sequences, experiments);

    print_indent(-1);

    document.link(failures_document.url, 'Failure analysis');

end;

if difficulty

    print_text('Difficulty report ...'); print_indent(1);

    difficulty_document = report_difficulty(context, trackers, sequences, experiments, 'uselabels', true, 'usepractical', true);

    print_indent(-1);

    document.link(difficulty_document.url, 'Difficulty analysis');

end;

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

document.section('Overall ranking');

N_scores = numel(score_labels);
combined_scores = squeeze(mean(scores, 1));

overall_scores = sum(combined_scores(:) .* repmat(score_weights, numel(trackers), 1), 2) ./ sum(score_weights(:));
[~, order] = sort(overall_scores, sort_direction)  ;

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', 0);

column_labels = cell(2, N_scores * numel(experiments) + 1);

column_labels(1, :) = repmat({struct()}, 1, size(column_labels, 2));
column_labels(1, 1:N_scores:end-1) = cellfun(@(x) struct('text', x.name, 'columns', N_scores), experiments,'UniformOutput',false);
column_labels(2, :) = [score_labels(repmat(1:length(score_labels), 1, numel(experiments))), {'Overall'}];

experiments_ranking_data = zeros(N_scores * numel(experiments), numel(trackers));
for i = 1:N_scores
    experiments_ranking_data(i:N_scores:end) = scores(:, :, i);
end
experiments_ranking_data = num2cell(experiments_ranking_data);

overall_ranking_data = num2cell(overall_scores);

tabledata = cat(1, experiments_ranking_data, overall_ranking_data')';
tabledata = highlight_best_rows(tabledata, cat(2, repmat(score_sorting_partial, 1, numel(experiments)), {score_sorting_overall}));

document.table(tabledata(order, :), 'columnLabels', column_labels, 'rowLabels', tracker_labels(order), 'format', score_format);

document.write();
