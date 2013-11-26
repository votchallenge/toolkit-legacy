function [index_file, ranks] = ranking_analysis(directory, trackers, sequences, experiments, labels, varargin)

temporary_dir = tempdir;

ranks = nan(numel(experiments) * 3, numel(trackers));

image_directory = fullfile(directory, 'images');
temporary_index_file = fullfile(temporary_dir, 'index.tmp');
template_file = fullfile(fileparts(mfilename('fullpath')), 'report.html');

experiment_names = cellfun(@(x) x.name, experiments,'UniformOutput',false);

mkpath(image_directory);

index_fid = fopen(temporary_index_file, 'w');

t_labels = cellfun(@(tracker) tracker.identifier, trackers, 'UniformOutput', 0);

combine_weight = 0.5 ;

colors = repmat(hsv(7), ceil(length(trackers) / 7), 1);
latex_fid = [];

style = repmat({'o', 'x', '*', 'v', 'd', '+', '<', 'p', '>'}, 1, ceil(length(trackers) / 9));
style = style(1:length(trackers));

style(2, :) = mat2cell(colors(1:length(trackers), :), ones(length(trackers), 1), 3);
style(3, :) = num2cell(mod(1:length(trackers), 5) / 5 + 1.5);

report_filename = 'ranking.html';

minimal_difference_acc = 0;
minimal_difference_fail = 0;
ar_plot = 0;
permutation_plot = 0;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'combineweight'
            combine_weight = varargin{i+1}; 
        case 'latexfile'
            latex_fid = varargin{i+1};
        case 'reporttemplate'
            template_file = varargin{i+1}; 
        case 'minimaldifferenceaccuracy'
            minimal_difference_acc = varargin{i+1} ;
        case 'minimaldifferencefailure'
            minimal_difference_fail = varargin{i+1} ;
        case 'arplot'
            ar_plot = varargin{i+1} ;
        case 'permutationplot'
            permutation_plot = varargin{i+1} ;              
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

index_file = fullfile(directory, report_filename);

for e = 1:numel(experiments)

    experiment = experiments{e};

    print_text('Ranking analysis for experiment %s ...', experiment.name);

    print_indent(1);

    print_text('Loading data ...');

    [S_all, F_all, t_available] = ...
        process_results_labels(trackers, convert_sequences(sequences, experiment.converter), ...
        labels, experiment.name);

    S_all = cellfun(@(x) x(t_available, :), S_all, 'UniformOutput', 0);
    F_all = cellfun(@(x) x(t_available, :), F_all, 'UniformOutput', 0);
    
    print_text('Processing ...');

    % Start evaluation 
    type_comparison = 'Wilcoxon' ; % Wilcoxon, Prob_better
    alpha = 0.05 ;

    [accuracy, robustness] = ranking(S_all, F_all, t_labels(t_available), ...
                                'alpha', alpha, 'minimal_difference_acc', minimal_difference_acc,...
                                'minimal_difference_fail', minimal_difference_fail, ...
                                'type_comparison', type_comparison ) ;

    print_indent(-1);

    print_text('Writing report ...');

    temporary_file = fullfile(temporary_dir, 'tables.tmp');

    generate_ranking_report(temporary_file, accuracy, robustness, ...
        'trackerLabels', t_labels(t_available), 'sequenceLabels', labels, ...
        'combineWeight', combine_weight);

    fprintf(index_fid, '<h2>Experiment %s</h2>\n', experiment.name);
           
    if ar_plot
    
        for l = 1:length(labels)
            label = labels{l};
            h = generate_ranking_plot(accuracy.ranks(l, :), robustness.ranks(l, :), ...
                sprintf('Experiment %s, label %s', experiment.name, label), ...
                t_labels(t_available), style(:, t_available), length(trackers));
            
            export_figure(h, fullfile(image_directory, sprintf('ranking_%s_%s', experiment.name, label)), 'png');
        end;

        h = generate_ranking_plot(accuracy.average_ranks, robustness.average_ranks, ...
            sprintf('Experiment %s', experiment.name), ...
            t_labels(t_available), style(:, t_available), length(trackers));

        export_figure(h, fullfile(image_directory, sprintf('ranking_%s', experiment.name)), 'png');
        
        fprintf(index_fid, '<p><img src="images/ranking_%s.png" alt="%s" /></p>\n', experiment.name, experiment.name);
 
    end;

    if permutation_plot

        h = generate_permutation_plot(accuracy.ranks, labels, ...
            'Ranking permutations for accuracy rank', t_labels(t_available), style(:, t_available));

        export_figure(h, fullfile(image_directory, ...
            sprintf('permutation_accuracy_%s', experiment.name)), 'png');
        
        h = generate_permutation_plot(robustness.ranks, labels, ...
            'Ranking permutations for robustness rank', t_labels(t_available), style(:, t_available));

        export_figure(h, fullfile(image_directory, ...
            sprintf('permutation_robustness_%s', experiment.name)), 'png');
        
        combined_ranks = accuracy.ranks * combine_weight ...
            + robustness.ranks * (1-combine_weight);
        
        h = generate_permutation_plot(combined_ranks, labels, ...
            'Ranking permutations for combined rank', t_labels(t_available), style(:, t_available)); 

        export_figure(h, fullfile(image_directory, ...
            sprintf('permutation_combined_%s', experiment.name)), 'png');
        
        fprintf(index_fid, '<h2>Ranking permutations</h2>\n');    

        fprintf(index_fid, '<p><img src="images/permutation_accuracy_%s.png" alt="Ranking permutations for accuracy rank" /></p>\n', experiment.name);

        fprintf(index_fid, '<p><img src="images/permutation_robustness_%s.png" alt="Ranking permutations for robustness rank" /></p>\n', experiment.name);

        fprintf(index_fid, '<p><img src="images/permutation_combined_%s.png" alt="Ranking permutations for combined rank" /></p>\n', experiment.name);

    end;
    
    
    ranks(e * 3 - 2, t_available) = accuracy.average_ranks;
    ranks(e * 3 - 1, t_available) = robustness.average_ranks;
    ranks(e * 3, t_available) = accuracy.average_ranks * combine_weight + robustness.average_ranks * (1-combine_weight);
       
    [~, order] = sort(ranks(e * 3, :), 'ascend');
    print_average_ranks(index_fid, ranks(e * 3, order), t_labels(order));

    report_file = fullfile(directory, sprintf('ranking-%s.html', experiment.name));
    
    fprintf(index_fid, '<a href="ranking-%s.html">More information</a>\n', experiment.name);
    
    generate_from_template(report_file, template_file, ...
        'body', fileread(temporary_file), 'title', sprintf('Ranking report for experiment %s', experiment.name), ...
        'timestamp', datestr(now, 31));

    delete(temporary_file);

end;

ranks(isnan(ranks)) = size(ranks, 2);

fprintf(index_fid, '<h2>Averaged</h2>\n');
mean_ranks = mean(ranks(3:3:end, :), 1);
[~, order] = sort(mean_ranks,'ascend')  ;
print_average_ranks(index_fid, mean_ranks(order), t_labels(order));

if permutation_plot

    h = generate_permutation_plot(ranks(1:3:end, :), experiment_names, ...
        'Ranking permutations for accuracy rank', t_labels, style);

    export_figure(h, fullfile(image_directory, 'permutation_accuracy'), 'png');
    
    h = generate_permutation_plot(ranks(2:3:end, :), experiment_names, ...
        'Ranking permutations for robustness rank', t_labels, style);

    export_figure(h, fullfile(image_directory, 'permutation_robustness'), 'png');
            
    h = generate_permutation_plot(ranks(3:3:end, :), experiment_names, ...
        'Ranking permutations for combined rank', t_labels, style); 

    export_figure(h, fullfile(image_directory, 'permutation_combined'), 'png');
    
    fprintf(index_fid, '<h2>Ranking permutations</h2>\n');    
    
    fprintf(index_fid, '<p><img src="images/permutation_accuracy.png" alt="Ranking permutations for accuracy rank" /></p>\n');
     
    fprintf(index_fid, '<p><img src="images/permutation_robustness.png" alt="Ranking permutations for robustness rank" /></p>\n');
    
    fprintf(index_fid, '<p><img src="images/permutation_combined.png" alt="Ranking permutations for combined rank" /></p>\n');
    
end;


fclose(index_fid);

if ~isempty(latex_fid)

    ranks(end+1, :) = mean_ranks;
    
    ordered_ranks = ranks(:, order);

    fprintf(latex_fid, '\\begin{table}[h!]\\caption{Ranking results}\\label{tab:ranking}\n\\centering');

    ranking_labels = {'$R_A$', '$R_R$', '$R$'};
    

    prefix = [str2latex(sprintf([' & \\multicolumn{' num2str(length(ranking_labels)) '}{|c|}{ %s } '], experiment_names{:})), ' & '];
    
    column_labels = [ranking_labels(repmat(1:length(ranking_labels), 1, numel(experiments))),  {'$R_{\Sigma}$'}];
        
    celldata = num2cell(ordered_ranks');
    
    for i = 1:size(celldata, 2)
        scores = ordered_ranks(i, :);
        scores(isnan(scores)) = length(trackers);
        [~, indices] = sort(scores, 'ascend');
        
        celldata{indices(1), i} = sprintf('\\first{%.2f}', celldata{indices(1), i});
        celldata{indices(2), i} = sprintf('\\second{%.2f}', celldata{indices(2), i});
        celldata{indices(3), i} = sprintf('\\third{%.2f}', celldata{indices(3), i});
    end;
    
    matrix2latex(celldata, latex_fid, 'columnLabels', column_labels, 'rowLabels', strrep(t_labels(order), '_', '\_'), 'format', '%.2f', ...
            'prefix', prefix);

    fprintf(latex_fid, '\\end{table}\n');

end;

generate_from_template(index_file, template_file, ...
    'body', fileread(temporary_index_file), 'title', 'Ranking report', ...
    'timestamp', datestr(now, 31));

function print_average_ranks(fid, ranks, t_labels )

    table = cellfun(@(x) sprintf('%1.3g', x), num2cell(ranks), 'UniformOutput', 0);

    matrix2html(table, fid, 'columnLabels', t_labels);


