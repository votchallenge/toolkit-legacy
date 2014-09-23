function [document] = report_challenge(context, experiments, trackers, sequences, varargin)

arplot = true;
permutationplot = true;
ratio = 0.5;

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'arplot'
            arplot = varargin{i+1};
        case 'permutationplot'
            permutationplot = varargin{i+1};
        case 'combineweight'
            ratio = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end 


document = create_document(context, 'challenge', 'title', 'VOT competition report');

print_text('Generating competition report'); print_indent(1);

print_text('Speed report ...'); print_indent(1);

[normalized, original] = analyze_speed(experiments, trackers(1:5), sequences);

averaged_normalized = squeeze(mean(mean(normalized, 3), 1));
averaged_original = squeeze(mean(mean(original, 3), 1));
normalized
averaged_normalized
return;

% TODO: write detailed report (implementation and raw speed)

print_indent(-1);

print_text('Ranking report ...'); print_indent(1);

[ranking_document, ranks] = report_ranking(context, trackers, sequences, experiments, ...
    'uselabels', true, 'usepractical', true, 'arplot', arplot, 'permutationplot', permutationplot);

combined_ranks = squeeze(mean(ranks, 1));

overall_ranks = ratio * combined_ranks(:, 1) + (1 - ratio) * combined_ranks(:, 2);
[~, order] = sort(overall_ranks,'ascend')  ;

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', 0);

column_labels = cell(2, 2 * numel(experiments) + 4);

ranking_labels = {'Acc. Rank', 'Rob. Rank'};
column_labels(1, :) = repmat({struct()}, 1, size(column_labels, 2));
column_labels(1, 1:2:end-4) = cellfun(@(x) struct('text', x.name, 'columns', 2), experiments,'UniformOutput',false);
column_labels{1, end-3} = struct('text', '', 'columns', 4);
column_labels(2, :) = [ranking_labels(repmat(1:length(ranking_labels), 1, numel(experiments) + 1)), {'Rank', 'Speed'}];

experiments_ranking_data = zeros(2 * numel(experiments), numel(trackers));
experiments_ranking_data(1:2:end) = ranks(:, :, 1);
experiments_ranking_data(2:2:end) = ranks(:, :, 2);
experiments_ranking_data = num2cell(experiments_ranking_data);

overall_ranking_data = num2cell(cat(2, combined_ranks, overall_ranks)');
speed_data = num2cell(averaged_normalized);

tabledata = cat(1, experiments_ranking_data, overall_ranking_data, speed_data)';

ordering = [repmat({'ascending'}, 1, numel(experiments) * 2 + 3), 'descending'];
tabledata = highlight_best_rows(tabledata, ordering);

document.table(tabledata(order, :), 'columnLabels', column_labels, 'rowLabels', tracker_labels(order));

document.link(ranking_document.url, 'Detailed ranking results');

document.write();
