function [document] = report_difficulty(context, trackers, sequences, experiments, varargin)
% report_difficulty Generate a difficulty report for labels or sequences
%
% Performs A-R ranking analysis and generates a report that shows the difficulty of individual
% labels or sequences.
%
% Input:
% - context (structure): Report context structure.
% - trackers (cell): An array of tracker structures.
% - sequences (cell): An array of sequence structures.
% - experiments (cell): An array of experiment structures.
% - varargin[UsePractical] (boolean): Use practical difference.
% - varargin[UseLabels] (boolean): Rank according to labels (otherwise rank according to sequences).
% - varargin[Alpha] (boolean): Statistical significance parameter.
%
% Output:
% - document (structure): Resulting document structure.
%

uselabels = true;
usepractical = true;
alpha = 0.05;
adaptation = get_global_variable('report_ranking_adaptation', 'mean');

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

trackers_hash = md5hash(strjoin((cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');
parameters_hash = md5hash(sprintf('%f-%d-%d-%s', alpha, uselabels, usepractical, adaptation));

for e = 1:length(experiments)

    document.section('Experiment %s', experiments{e}.name);
    
    labels = {};
    
    if uselabels && isfield(experiments{e}, 'labels')
        labels = experiments{e}.labels;
                
        sequences_hash = md5hash(strjoin(labels, '-'), 'Char', 'hex');
    else
        sequences_hash = md5hash(strjoin((cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');
    end;
    
    cache_identifier = sprintf('ranking_%s_%s_%s_%s', experiments{e}.name, trackers_hash, sequences_hash, parameters_hash);
    
    result = report_cache(context, cache_identifier, @analyze_ranks, experiments{e}, trackers, ...
        sequences, 'labels', labels, 'usepractical', usepractical, ...
        'alpha', alpha, 'adaptation', adaptation);
    
    selector_labels = result.labels;

    median_accuracy = nanmedian(result.accuracy.values, 2);
    median_robustness = nanmedian(result.robustness.normalized, 2);
    
    median_diff_accuracy = nanmedian(bsxfun(@minus, result.accuracy.values, mean(result.accuracy.values, 1)), 2);
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
        
        plot(ones(size(result.accuracy.values(i, :))) * i, result.accuracy.values(i, :), 'bo');        
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
    set(gca, 'YLim', [0, max(result.robustness.normalized(:))], ...
        'XLim', [0.5, numel(selector_labels) + 0.5], 'XTick', 1:numel(selector_labels), 'XTickLabel', selector_labels);
    
    document.figure(hf, sprintf('difficulty_%s_robustness_scatter', experiments{e}.name), ...
        sprintf('Robustness scatter'));    
    
    document.raw('</div>\n');
end;



document.write();

end

