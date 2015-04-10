function [document] = report_difficulty(context, trackers, sequences, experiments, varargin)

uselabels = true;
usepractical = true;
average = 'weighted_mean';
alpha = 0.05;

for i = 1:2:length(varargin)
    switch lower(varargin{i}) 
        case 'usepractical'
            usepractical = varargin{i+1};
        case 'uselabels'
            uselabels = varargin{i+1};
        case 'alpha'
            alpha = varargin{i+1}; 
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end 

document = create_document(context, 'difficulty', 'title', 'Difficulty');

for e = 1:length(experiments)

    document.section('Experiment %s', experiments{e}.name);
    
    [result] = analyze_ranks(experiments{e}, trackers, ...
        sequences, 'uselabels', uselabels, 'usepractical', usepractical, ...
        'average', average, 'alpha', alpha, 'cache', context.cachedir, 'adaptation', 'mean');

    if isfield(experiments{e}, 'labels') && uselabels
        selector_labels = experiments{e}.labels;
    else
        selector_labels = cellfun(@(x) x.name, sequences, 'UniformOutput', 0);
    end

    median_accuracy = nanmedian(result.accuracy.value, 2);
    median_robustness = nanmedian(result.robustness.normalized, 2);
    
    median_diff_accuracy = nanmedian(bsxfun(@minus, result.accuracy.value, mean(result.accuracy.value, 1)), 2);
    median_diff_robustness = nanmedian(bsxfun(@minus, result.robustness.normalized, mean(result.robustness.normalized, 1)), 2);
    
    table_data = [median_accuracy, median_robustness * 100, median_diff_accuracy, median_diff_robustness * 100];
    
    table_data = highlight_best_rows(num2cell(table_data), {'ascending', 'descending', 'ascending', 'descending'})';    
    row_labels = {'Accuracy', 'Robustness', 'Accuracy difference', 'Robustness difference'};
    
    title = sprintf('Difficulty for experiment %s', experiments{e}.name);
    
    document.table(table_data, 'columnLabels', selector_labels, 'rowLabels', row_labels', 'title', title);

    document.raw('<div class="imagegrid">\n');
    
    hf = figure('Visible', 'off');
    hold on;
    for i = 1:numel(selector_labels)
        if median_diff_accuracy(i) > 0
            rectangle('Position',[i-0.3, 0.5, 0.6, median_diff_accuracy(i)], 'FaceColor', 'green');
        elseif median_diff_accuracy(i) < 0
            rectangle('Position',[i-0.3, 0.5+median_diff_accuracy(i), 0.6, -median_diff_accuracy(i)], 'FaceColor', 'red');
        end;
        
        plot(ones(size(result.accuracy.value(i, :))) * i, result.accuracy.value(i, :), 'bo');        
    end
    hold off;
    set(gca, 'YLim', [0, 1], 'XLim', [0.5, numel(selector_labels) + 0.5], 'XTick', 1:numel(selector_labels), 'XTickLabel', selector_labels);
    
    document.figure(hf, sprintf('difficulty_%s_accuracy_scatter', experiments{e}.name), ...
        sprintf('Accuracy scatter'));

    hf = figure('Visible', 'off');
    hold on;
    origin = mean(median_robustness);
    for i = 1:numel(selector_labels)
        if median_diff_robustness(i) > 0
            rectangle('Position',[i-0.3, origin, 0.6, median_diff_robustness(i)], 'FaceColor', 'red');
        elseif median_diff_robustness(i) < 0
            rectangle('Position',[i-0.3, origin+median_diff_robustness(i), 0.6, -median_diff_robustness(i)], 'FaceColor', 'green');
        end;
        
        plot(ones(size(result.robustness.normalized(i, :))) * i, result.robustness.normalized(i, :), 'bo');        
    end
    hold off;
    set(gca, 'YLim', [0, max(result.robustness.normalized(:))], 'XLim', [0.5, numel(selector_labels) + 0.5], 'XTick', 1:numel(selector_labels), 'XTickLabel', selector_labels);
    
    document.figure(hf, sprintf('difficulty_%s_robustness_scatter', experiments{e}.name), ...
        sprintf('Robustness scatter'));    
    
    document.raw('</div>\n');
end;



document.write();

end

