function [document, averaged_ranks] = report_ranking(context, trackers, sequences, experiments, varargin)

uselabels = get_global_variable('report_labels', true);
usepractical = get_global_variable('report_ranking_practical', true);
permutationplot = get_global_variable('report_ranking_permutationplot', false);
hidelegend = get_global_variable('report_legend_hide', false);
arplot = get_global_variable('report_ranking_arplot', true);
average = get_global_variable('report_ranking_average', 'weighted_mean');
adaptation = get_global_variable('report_ranking_adaptation', 'mean');
sensitivity = get_global_variable('report_ranking_sensitivity', 30);
alpha = 0.05;
table_format = 'accrob'; % joined, rankscores, accrob, fragmented
table_orientation = 'trackers'; % trackers, selectors, trackerscores, selectorscores

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'usepractical'
            usepractical = varargin{i+1};
        case 'uselabels'
            uselabels = varargin{i+1};
        case 'permutationplot'
            permutationplot = varargin{i+1};
        case 'arplot'
            arplot = varargin{i+1};
        case 'average'
            average = varargin{i+1};
        case 'alpha'
            alpha = varargin{i+1}; 
        case 'tableformat'
            table_format = varargin{i+1};
        case 'tableorientation'
            table_orientation = varargin{i+1};
        case 'hidelegend'
            hidelegend = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end 

document = create_document(context, 'ranking', 'title', 'AR ranking');

results = cell(length(experiments), 1);
averaged_ranks = nan(length(experiments), length(trackers), 2);

for e = 1:length(experiments)

    [result] = analyze_ranks(experiments{e}, trackers, ...
        sequences, 'uselabels', uselabels, 'usepractical', usepractical, ...
        'average', average, 'alpha', alpha, 'cache', context.cachedir, 'adaptation', adaptation);
    results{e} = result;
  
    averaged_ranks(e, :, 1) = result.accuracy.average_ranks;
    averaged_ranks(e, :, 2) = result.robustness.average_ranks;    
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
    
        document.raw('<div class="imagegrid">\n');

        plot_title = sprintf('Ranking plot for experiment %s', experiments{e}.name);
        plot_id = sprintf('rankingplot_%s', experiments{e}.name);

        hf = generate_ranking_plot(trackers, squeeze(averaged_ranks(e, :, 1)), ...
            squeeze(averaged_ranks(e, :, 2)), ...
            'title', plot_title, 'limit', numel(trackers), 'legend', ~hidelegend);

        document.figure(hf, plot_id, plot_title);

        close(hf);

        plot_title = sprintf('AR plot for experiment %s', experiments{e}.name);
        plot_id = sprintf('arplot_%s', experiments{e}.name);

        hf = generate_ar_plot(trackers, results{e}.accuracy.average_value, ...
            results{e}.robustness.average_normalized, ...
            'title', plot_title, 'sensitivity', sensitivity, 'legend', ~hidelegend);

        document.figure(hf, plot_id, plot_title);

        close(hf);

        document.raw('</div>\n');

    end;
    
    if isfield(experiments{e}, 'labels') && uselabels
        selector_labels = experiments{e}.labels;
    else
        selector_labels = cellfun(@(x) x.name, sequences, 'UniformOutput', 0);
    end

    score_labels = {'A-Rank', 'R-Rank', 'Overlap', 'Failures'};
    score_sorting = {'ascending', 'ascending', 'descending', 'ascending'};
    scores = cat(3, [results{e}.accuracy.ranks', results{e}.accuracy.average_ranks'], ...
        [results{e}.robustness.ranks', results{e}.robustness.average_ranks'], ...
        [results{e}.accuracy.value', results{e}.accuracy.average_value'], ...
        [results{e}.robustness.value', results{e}.robustness.average_value']);
    
    table_selector_labels = selector_labels;
    table_selector_labels{end+1} = create_table_cell('Overall', 'class', 'average'); %#ok<AGROW>
    
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

    if permutationplot
              
        document.raw('<div class="imagegrid">\n');
        
        h = generate_permutation_plot(trackers, results{e}.accuracy.ranks, selector_labels, ...
            'flip', 1, 'legend', ~hidelegend);
        document.figure(h, sprintf('permutation_accuracy_%s', experiments{e}.name), ...
            'Ranking permutations for accuracy rank');

        close(h);

        h = generate_permutation_plot(trackers, results{e}.accuracy.value, selector_labels, ...
            'scope', [0, 1], 'type', 'Overall overlap', 'legend', ~hidelegend);
        document.figure(h, sprintf('permutation_overlap_%s', experiments{e}.name), ...
            'Permutations for overall overlap');    

        close(h);

        document.raw('</div>\n');
        document.raw('<div class="imagegrid">\n');        
        
        h = generate_permutation_plot(trackers, results{e}.robustness.ranks, selector_labels, ...
            'flip', 1, 'legend', ~hidelegend);
        document.figure(h, sprintf('permutation_robustness_%s', experiments{e}.name), ...
            'Ranking permutations for robustness rank');

        close(h);

        robustness = results{e}.robustness.normalized .* sensitivity;
        
        h = generate_permutation_plot(trackers, robustness, selector_labels, ...
            'scope', [0, max(robustness(:))+eps], 'type', ...
            'Failures', 'legend', ~hidelegend);

        document.figure(h, sprintf('permutation_failures_%s', experiments{e}.name), ...
            'Permutations for failures');

        close(h);
            
        document.raw('</div>\n');
    end;

    if arplot

        for l = 1:length(selector_labels)

            document.raw('<div class="imagegrid">\n');

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

            hf = generate_ar_plot(trackers, results{e}.accuracy.value(l, :), ...
                results{e}.robustness.normalized(l, :), ...
                'title', plot_title, 'sensitivity', sensitivity, 'legend', ~hidelegend);

            document.figure(hf, plot_id, plot_title);

            close(hf);

            document.raw('</div>\n');

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
