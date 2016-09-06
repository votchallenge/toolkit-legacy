function [document, averaged_ranks] = report_ranking(context, trackers, sequences, experiments, varargin)
% report_ranking Generate a report based on A-R ranking
%
% Performs A-R ranking analysis and generates a report based on the results.
%
% Input:
% - context (structure): Report context structure.
% - trackers (cell): An array of tracker structures.
% - sequences (cell): An array of sequence structures.
% - experiments (cell): An array of experiment structures.
% - varargin[UsePractical] (boolean): Use practical difference.
% - varargin[UseLabels] (boolean): Rank according to labels (otherwise rank according to sequences).
% - varargin[Average] (string): How to compute average rank.
%     - weighted_mean: Average ranks, average values by taking into account length
%     - mean: Average ranks, average values
%     - pooled: gather all frames and compute ranking on a single combined sequence
% - varargin[Alpha] (double): Statistical significance parameter.
% - varargin[Adaptation] (string): Statistical significance parameter.
% - varargin[HideLegend] (boolean): Hide legend in plots.
%
% Output:
% - document (structure): Resulting document structure.
% - averaged_ranks (matrix): Averaged ranks for entire set.
%

uselabels = get_global_variable('report_labels', true);
usepractical = get_global_variable('report_ranking_practical', true);
orderingplot = get_global_variable('report_ranking_ordering', true);
hidelegend = get_global_variable('report_legend_hide', false);
arplot = get_global_variable('report_ranking_arplot', true);
average = get_global_variable('report_ranking_average', 'weighted_mean');
adaptation = get_global_variable('report_ranking_adaptation', 'mean');
sensitivity = get_global_variable('report_ranking_sensitivity', 30);
alpha = get_global_variable('report_ranking_alpha', 0.05);
table_format = get_global_variable('report_ranking_table_format', 'accrob'); % joined, rankscores, accrob, fragmented
table_orientation = get_global_variable('report_ranking_table_orientation', 'trackers'); % trackers, selectors, trackerscores, selectorscores

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'usepractical'
            usepractical = varargin{i+1};
        case 'uselabels'
            uselabels = varargin{i+1};
        case 'average'
            average = varargin{i+1};
        case 'alpha'
            alpha = varargin{i+1};
        case 'adaptation'
            adaptation = varargin{i+1};
        case 'hidelegend'
            hidelegend = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end 

if numel(trackers) < 2
    error('Ranking analysis requires two or more trackers.');
end;

if ~any(strcmp(average, {'mean', 'weighted_mean', 'pooled'}))         
   error('Unknown averaging technique "%s"!', average);
end
document = create_document(context, 'ranking', 'title', 'AR ranking');

% Filter out all experiments that are not of type "supervised"
experiments = experiments(cellfun(@(e) strcmp(e.type, 'supervised'), experiments, 'UniformOutput', true));

results = cell(length(experiments), 1);
averaged_ranks = nan(length(experiments), length(trackers), 2);

trackers_hash = md5hash(strjoin((cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');
parameters_hash = md5hash(sprintf('%f-%d-%d-%s', alpha, uselabels, usepractical, adaptation));
    
for e = 1:length(experiments)

    labels = {};
    
    if uselabels && isfield(experiments{e}, 'labels')
        labels = union(experiments{e}.labels, {'all'});        
        sequences_hash = md5hash(strjoin(labels, '-'), 'Char', 'hex');
    else
        sequences_hash = md5hash(strjoin((cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');
    end;
    
    cache_identifier = sprintf('ranking_%s_%s_%s_%s', experiments{e}.name, trackers_hash, sequences_hash, parameters_hash);

    result = report_cache(context, cache_identifier, @analyze_ranks, experiments{e}, trackers, ...
        sequences, 'labels', labels, 'usepractical', usepractical, ...
        'alpha', alpha, 'adaptation', adaptation);

    if uselabels
        % When using labels we have inserted a separate one for this
        mask = strcmp('label_all', result.labels);
        
        result.accuracy.pooled_values = result.accuracy.values(mask, :);
        result.robustness.pooled_values = result.robustness.values(mask, :);
        result.robustness.pooled_normalized = result.robustness.normalized(mask, :);
        result.accuracy.pooled_ranks = result.accuracy.ranks(mask, :);
        result.robustness.pooled_ranks = result.robustness.ranks(mask, :);

        % Now remove the 'all' label from results
        result.accuracy.values = result.accuracy.values(~mask, :);
        result.accuracy.ranks = result.accuracy.ranks(~mask, :);
        result.robustness.values = result.robustness.values(~mask, :);
        result.robustness.normalized = result.robustness.normalized(~mask, :);
        result.robustness.ranks = result.robustness.ranks(~mask, :);
        result.lengths = result.lengths(~mask);
        result.labels = result.labels(~mask); 
        
    end
    
    result.accuracy.weighted_mean_ranks = nanmean(result.accuracy.ranks, 1);
    result.robustness.weighted_mean_ranks = nanmean(result.robustness.ranks, 1);

    useable = result.lengths > 0;
    result.accuracy.weighted_mean_values = sum(result.accuracy.values(useable, :) ...
        .* repmat(result.lengths(useable), 1, length(trackers)), 1) ./ sum(result.lengths(useable));
    result.robustness.weighted_mean_values = sum(result.robustness.values(useable, :) ...
        .* repmat(result.lengths(useable), 1, length(trackers)), 1) ./ sum(result.lengths(useable));
    result.robustness.weighted_mean_normalized = sum(result.robustness.normalized(useable, :) ...
        .* repmat(result.lengths(useable), 1, length(trackers)), 1) ./ sum(result.lengths(useable));

    result.accuracy.mean_ranks = nanmean(result.accuracy.ranks, 1);
    result.robustness.mean_ranks = nanmean(result.robustness.ranks, 1);

    result.accuracy.mean_values = nanmean(result.accuracy.values, 1);
    result.robustness.mean_values = nanmean(result.robustness.values, 1);
    result.robustness.mean_normalized = nanmean(result.robustness.normalized, 1);   

    results{e} = result;

    switch average

        case 'weighted_mean'
            
            averaged_ranks(e, :, 1) = result.accuracy.weighted_mean_ranks;
            averaged_ranks(e, :, 2) = result.robustness.weighted_mean_ranks;

        case 'mean'
            
            averaged_ranks(e, :, 1) = result.accuracy.mean_ranks;
            averaged_ranks(e, :, 2) = result.robustness.mean_ranks;

        case 'pool'

            if uselabels
                averaged_ranks(e, :, 1) = result.accuracy.pooled_ranks;
                averaged_ranks(e, :, 2) = result.robustness.pooled_ranks;
            else
                averaged_ranks(e, :, 1) = result.accuracy.weighted_mean_ranks;
                averaged_ranks(e, :, 2) = result.robustness.weighted_mean_ranks;
            end
    end
    
end;

overall_ranks = squeeze(mean(averaged_ranks, 1)); % Averaged per-label and per-experiment

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', 0);

column_labels = cell(2, 2 * numel(experiments) + 2);

ranking_labels = {'Accuracy', 'Robustness'};
column_labels(1, 1:2:end-2) = cellfun(@(x) struct('text', x.name, 'columns', 2), experiments,'UniformOutput',false);
column_labels{1, end-1} = struct('text', 'Overall', 'columns', 2);
column_labels(1, 2:2:end) = repmat({struct()}, 1, numel(experiments) + 1);
column_labels(2, :) = ranking_labels(repmat(1:length(ranking_labels), 1, numel(experiments) + 1));

table_data = zeros(numel(trackers), 2 * numel(experiments) + 2);
table_data(:, 1:2:end) = [averaged_ranks(:, :, 1)', overall_ranks(:, 1)];
table_data(:, 2:2:end) = [averaged_ranks(:, :, 2)', overall_ranks(:, 2)];

table_data = highlight_best_rows(num2cell(table_data), repmat({'ascending'}, 1, numel(experiments) * 2 + 2));

print_text('Writing ranking table ...');

document.table(table_data, 'columnLabels', column_labels, 'rowLabels', tracker_labels);

for e = 1:length(experiments)

	print_text('Writing ranking details for experiment %s ...', experiments{e}.name);

    document.section('Experiment %s', experiments{e}.name);

    if arplot

        generate_ar_and_rank_plot(document, sprintf('%s_mean', experiments{e}.name), ...
            sprintf('experiment %s (mean)', experiments{e}.name), ...
            trackers, results{e}.accuracy.mean_ranks, ...
            results{e}.robustness.mean_ranks, ...
            results{e}.accuracy.mean_values, ...
            results{e}.robustness.mean_normalized, sensitivity, hidelegend);
        
        generate_ar_and_rank_plot(document, sprintf('%s_weighted_mean', experiments{e}.name), ...
            sprintf('experiment %s (weighted_mean)', experiments{e}.name), ...
            trackers, results{e}.accuracy.weighted_mean_ranks, ...
            results{e}.robustness.weighted_mean_ranks, ...
            results{e}.accuracy.weighted_mean_values, ...
            results{e}.robustness.weighted_mean_normalized, sensitivity, hidelegend);

        if uselabels
           
            generate_ar_and_rank_plot(document, sprintf('%s_pooled', experiments{e}.name), ...
            sprintf('experiment %s (pooled)', experiments{e}.name), ...
            trackers, results{e}.accuracy.pooled_ranks, ...
            results{e}.robustness.pooled_ranks, ...
            results{e}.accuracy.pooled_values, ...
            results{e}.robustness.pooled_normalized, sensitivity, hidelegend);
            
        end
        
    end;
    
    selector_labels = results{e}.labels;

    score_labels = {'A-Rank', 'R-Rank', 'Overlap', 'Failures'};
    score_sorting = {'ascending', 'ascending', 'descending', 'ascending'};
    scores = cat(3, results{e}.accuracy.ranks', ...
        results{e}.robustness.ranks', ...
        results{e}.accuracy.values', ...
        results{e}.robustness.values');
    scores = cat(2, scores, cat(3, results{e}.accuracy.mean_ranks', ...
        results{e}.robustness.mean_ranks', ...
        results{e}.accuracy.mean_values', ...
        results{e}.robustness.mean_values'));
    scores = cat(2, scores, cat(3, results{e}.accuracy.weighted_mean_ranks', ...
        results{e}.robustness.weighted_mean_ranks', ...
        results{e}.accuracy.weighted_mean_values', ...
        results{e}.robustness.weighted_mean_values'));
    
    table_selector_labels = selector_labels;
    table_selector_labels{end+1} = create_table_cell('Mean', 'class', 'average'); %#ok<AGROW>
    table_selector_labels{end+1} = create_table_cell('Weighted mean', 'class', 'average'); %#ok<AGROW>
    
    if uselabels
        scores = cat(2, scores, cat(3, results{e}.accuracy.pooled_ranks', ...
            results{e}.robustness.pooled_ranks', ...
            results{e}.accuracy.pooled_values', ...
            results{e}.robustness.pooled_values'));
        table_selector_labels{end+1} = create_table_cell('Pooled', 'class', 'average'); %#ok<AGROW>
    end
    
    switch table_format
        case 'joined'
            print_scores_table(document, scores, score_sorting, score_labels, tracker_labels, table_selector_labels, table_orientation, 'Ranks and raw scores');
        case 'rankscores'
            print_scores_table(document, scores(:, :, 1:2), score_sorting(1:2), score_labels(1:2), tracker_labels, table_selector_labels, table_orientation, 'Ranks');
            print_scores_table(document, scores(:, :, 3:4), score_sorting(3:4), score_labels(3:4), tracker_labels, table_selector_labels, table_orientation, 'Raw scores');
        case 'accrob'
            print_scores_table(document, scores(:, :, [1,3]), score_sorting([1,3]), score_labels([1,3]), tracker_labels, table_selector_labels, table_orientation, 'Accuracy');
            print_scores_table(document, scores(:, :, [2,4]), score_sorting([2,4]), score_labels([2,4]), tracker_labels, table_selector_labels, table_orientation, 'Robustness');
        case 'fragmented'
            for t = 1:numel(score_labels)
                print_scores_table(document, scores(:, :, t), score_sorting(t), score_labels(t), tracker_labels, table_selector_labels, table_orientation, score_labels{t});
            end;
    end
    
    document.subsection('Detailed plots');

    if orderingplot
              
        h = generate_ordering_plot(trackers, results{e}.accuracy.ranks, selector_labels, ...
            'flip', 1, 'legend', ~hidelegend);
        document.figure(h, sprintf('ordering_accuracy_%s', experiments{e}.name), ...
            'Ranking orderings for accuracy rank');

        close(h);

        h = generate_ordering_plot(trackers, results{e}.accuracy.values, selector_labels, ...
            'scope', [0, 1], 'type', 'Overall overlap', 'legend', ~hidelegend);
        document.figure(h, sprintf('ordering_overlap_%s', experiments{e}.name), ...
            'Orderings for overall overlap');    

        close(h);

        h = generate_ordering_plot(trackers, results{e}.robustness.ranks, selector_labels, ...
            'flip', 1, 'legend', ~hidelegend);
        document.figure(h, sprintf('ordering_robustness_%s', experiments{e}.name), ...
            'Ranking orderings for robustness rank');

        close(h);

        robustness = results{e}.robustness.normalized .* sensitivity;
        
        h = generate_ordering_plot(trackers, robustness, selector_labels, ...
            'scope', [0, max(robustness(:))+eps], 'type', ...
            'Failures', 'legend', ~hidelegend);

        document.figure(h, sprintf('ordering_failures_%s', experiments{e}.name), ...
            'Orderings for failures');

        close(h);

    end;

    if arplot

        for l = 1:length(selector_labels)

            plot_title = sprintf('Ranking plot for label %s in experiment %s', ...
                selector_labels{l}, experiments{e}.name);
            plot_id = sprintf('rankingplot_%s_%s', ...
                experiments{e}.name, selector_labels{l});

            hf = generate_ranking_plot(trackers, results{e}.accuracy.ranks(l, :)', ...
                results{e}.robustness.ranks(l, :)', ...
                'title', plot_title, 'limit', numel(trackers), 'legend', ~hidelegend);

            document.figure(hf, plot_id, plot_title);   

            close(hf);

            plot_title = sprintf('AR plot for label %s in experiment %s', ...
                selector_labels{l}, experiments{e}.name);
            plot_id = sprintf('arplot_%s_%s', experiments{e}.name, selector_labels{l});

            hf = generate_ar_plot(trackers, results{e}.accuracy.values(l, :), ...
                results{e}.robustness.normalized(l, :), ...
                'title', plot_title, 'sensitivity', sensitivity, 'legend', ~hidelegend);

            document.figure(hf, plot_id, plot_title);

            close(hf);

        end;
    
    end;
    
end;

document.write();

end

% --------------------------------------------------------------------- %

function print_scores_table(document, scores, score_sorting, score_labels, tracker_labels, selector_labels, orientation, title)

    % Scores - selectors x trackers x scores

    score_count = numel(score_labels);
    selector_count = numel(selector_labels);
    tracker_count = numel(tracker_labels);
    
    switch orientation
        case 'trackers'
            row_labels = tracker_labels;
            column_labels = selector_labels;
            row_scores = false;
            sort_columns = false;
        case 'selectors'
            row_labels = selector_labels;
            column_labels = tracker_labels;
            row_scores = false;
            sort_columns = true;
        case 'trackerscores'
            row_labels = tracker_labels;
            column_labels = selector_labels;
            row_scores = true;
            sort_columns = true;
        case 'selectorscores'
            row_labels = selector_labels;
            column_labels = tracker_labels;
            row_scores = true;
            sort_columns = false;
        otherwise
            error('Unknown format %s', orientation);
    end

    column_labels = column_labels(:)';
    row_labels = row_labels(:);
    
    row_count = numel(row_labels);
    column_count = numel(column_labels);
    
    if sort_columns
        table_data = cell(tracker_count * score_count, selector_count);
        
        for s = 1:score_count
            score_table_data = highlight_best_rows(num2cell(scores(:, :, s)), ...
                repmat(score_sorting(s), 1, numel(selector_labels)));
            table_data(s:score_count:end, :) = score_table_data;
        end
        
        if ~row_scores
            table_data = table_data';
        end
    else
        table_data = cell(tracker_count, selector_count * score_count);
        
        for s = 1:score_count
            score_table_data = highlight_best_rows(num2cell(scores(:, :, s)), ...
                repmat(score_sorting(s), 1, numel(selector_labels)));
            table_data(:, s:score_count:end) = score_table_data;
        end
        
        if row_scores
            table_data = table_data';
        end
    end
    
    if row_scores
        
        if score_count > 1
            row_labels_exp = cell(score_count * row_count, 2);
            row_labels_exp(:, 1) = repmat({struct()}, 1, row_count * score_count);
            row_labels_exp(1:score_count:end, 1) = cellfun(@(x) create_table_cell(x, 'rows', score_count), row_labels, 'UniformOutput', false);
            row_labels_exp(:, 2) = score_labels(repmat(1:score_count, 1, row_count));
            row_labels = row_labels_exp;
        end
        
    else
        
        if score_count > 1
            column_labels_exp = cell(2, score_count * column_count);
            column_labels_exp(1, :) = repmat({struct()}, 1, column_count * score_count);
            column_labels_exp(1, 1:score_count:end) = cellfun(@(x) create_table_cell(x, 'columns', score_count), column_labels, 'UniformOutput', false);
            column_labels_exp(2, :) = score_labels(repmat(1:score_count, 1, column_count));
            column_labels = column_labels_exp;
        end
        
    end;

    document.table(table_data, 'columnLabels', column_labels, 'rowLabels', row_labels, 'title', title);

end

function generate_ar_and_rank_plot(document, identifier, title, trackers, ...
    accuracy_ranks, robustness_ranks, accuracy_values, ...
    robustness_values, sensitivity, hidelegend)

    plot_title = sprintf('Ranking plot for %s', title);
    plot_id = sprintf('rankingplot_%s', identifier);

    hf = generate_ranking_plot(trackers, accuracy_ranks, ...
        robustness_ranks, ...
        'title', plot_title, 'limit', numel(trackers), 'legend', ~hidelegend);

    document.figure(hf, plot_id, plot_title);

    close(hf);

    plot_title = sprintf('AR plot for %s', title);
    plot_id = sprintf('arplot_%s', identifier);

    hf = generate_ar_plot(trackers, accuracy_values, ...
        robustness_values, ...
        'title', plot_title, 'sensitivity', sensitivity, 'legend', ~hidelegend);

    document.figure(hf, plot_id, plot_title);

    close(hf);
    
end