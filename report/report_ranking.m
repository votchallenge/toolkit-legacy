function [document, averaged_ranks] = report_ranking(context, trackers, sequences, experiments, varargin)

uselabels = false;
usepractical = false;
permutationplot = false;
arplot = true;
average = 'mean';
sensitivity = 30;

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
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end 

document = create_document(context, 'ranking', 'title', 'AR ranking');

results = cell(length(experiments), 1);
averaged_ranks = nan(length(experiments), length(trackers), 2);
averaged_scores = nan(length(experiments), length(trackers), 2);

for e = 1:length(experiments)

    [result] = analyze_ranks(experiments{e}, trackers, ...
        sequences, 'uselabels', uselabels, 'usepractical', usepractical, ...
        'average', average);
    results{e} = result;
  
    averaged_ranks(e, :, 1) = result.accuracy.average_ranks;
    averaged_ranks(e, :, 2) = result.robustness.average_ranks;    
    averaged_scores(e, :, 1) = result.accuracy.average_value;
    averaged_scores(e, :, 2) = result.robustness.average_value ./ result.robustness.length;
end;

overall_ranks = squeeze(mean(averaged_ranks, 1)); % Averaged per-label and per-experiment

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', 0);

column_labels = cell(2, 2 * numel(experiments) + 2);

ranking_labels = {'Acc. Rank', 'Rob. Rank'};
column_labels(1, 1:2:end-2) = cellfun(@(x) struct('text', x.name, 'columns', 2), experiments,'UniformOutput',false);
column_labels{1, end-1} = struct('text', 'Averaged', 'columns', 2);
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
    
    % TODO: detailed tables of per-selector rankings and raw scores 

    if arplot
    
        document.raw('<div class="imagegrid">\n');

        plot_title = sprintf('Ranking plot for experiment %s', experiments{e}.name);
        plot_id = sprintf('rankingplot_%s', experiments{e}.name);

        hf = generate_ranking_plot(trackers, squeeze(averaged_ranks(e, :, 1)), ...
            squeeze(averaged_ranks(e, :, 2)), ...
            'title', plot_title, 'limit', numel(trackers));

        document.figure(hf, plot_id, plot_title);

        plot_title = sprintf('AR plot for experiment %s', experiments{e}.name);
        plot_id = sprintf('arplot_%s', experiments{e}.name);

        hf = generate_ar_plot(trackers, squeeze(averaged_scores(e, :, 1)), ...
            squeeze(averaged_scores(e, :, 2)), ...
            'title', plot_title, 'sensitivity', sensitivity);

        document.figure(hf, plot_id, plot_title);

        document.raw('</div>\n');

    end;
    
    if isfield(experiments{e}, 'labels') && uselabels
        selector_labels = experiments{e}.labels;
    else
        selector_labels = cellfun(@(x) x.name, sequences, 'UniformOutput', 0);
    end

    print_experiment_table(document, results{e}, tracker_labels, selector_labels );

    document.subsection('Detailed plots');

    if permutationplot
              
        document.raw('<div class="imagegrid">\n');        
        
        h = generate_permutation_plot(trackers, results{e}.accuracy.ranks, selector_labels, 'flip', 1);
        document.figure(h, sprintf('permutation_accuracy_%s', experiments{e}.name), ...
            'Ranking permutations for accuracy rank');

        h = generate_permutation_plot(trackers, results{e}.accuracy.value, selector_labels, 'scope', [0, 1], 'type', 'Average overlap');
        document.figure(h, sprintf('permutation_overlap_%s', experiments{e}.name), ...
            'Permutations for average overlap');    

        document.raw('</div>\n');
        document.raw('<div class="imagegrid">\n');        
        
        h = generate_permutation_plot(trackers, results{e}.robustness.ranks, selector_labels, 'flip', 1);
        document.figure(h, sprintf('permutation_robustness_%s', experiments{e}.name), ...
            'Ranking permutations for robustness rank');

        h = generate_permutation_plot(trackers, results{e}.robustness.value, selector_labels, ...
            'scope', [0, max(results{e}.robustness.value(:))+1], 'type', 'Failures');
        document.figure(h, sprintf('permutation_failures_%s', experiments{e}.name), ...
            'Permutations for failures');
        
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
                'title', plot_title, 'limit', numel(trackers));

            document.figure(hf, plot_id, plot_title);   

            plot_title = sprintf('AR plot for label %s in experiment %s', ...
                selector_labels{l}, experiments{e}.name);
            plot_id = sprintf('arplot_%s_%s', experiments{e}.name, selector_labels{l});

            hf = generate_ar_plot(trackers, results{e}.accuracy.value(l, :), ...
                results{e}.robustness.value(l, :) ./ results{e}.robustness.length, ...
                'title', plot_title, 'sensitivity', sensitivity);

            document.figure(hf, plot_id, plot_title);

            document.raw('</div>\n');

        end;
    
    end;
    
end;

document.write();

end

% --------------------------------------------------------------------- %
function print_experiment_table(document, results, tracker_labels, selector_labels)

column_labels = cell(2, 4 * numel(selector_labels));

ranking_labels = {'Acc. Rank', 'Rob. Rank', 'Overlap', 'Failures'};
column_labels(1, :) = repmat({struct()}, 1, numel(selector_labels) * 4);
column_labels(1, 1:4:end) = cellfun(@(x) struct('text', x, 'columns', 4), selector_labels,'UniformOutput', false);
column_labels(2, :) = ranking_labels(repmat(1:length(ranking_labels), 1, numel(selector_labels)));

table_data = zeros(numel(tracker_labels), 4 * numel(selector_labels));
table_data(:, 1:4:end) = results.accuracy.ranks';
table_data(:, 2:4:end) = results.robustness.ranks';
table_data(:, 3:4:end) = results.accuracy.value';
table_data(:, 4:4:end) = results.robustness.value';

table_data = highlight_best_rows(num2cell(table_data), ...
    repmat({'ascending', 'ascending', 'descending', 'ascending'}, 1, numel(selector_labels)));

document.table(table_data, 'columnLabels', column_labels, 'rowLabels', tracker_labels);

end

