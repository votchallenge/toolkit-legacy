function [index_file] = ranking_analysis(directory, trackers, sequences, experiments, labels, varargin)

temporary_dir = tempdir;

ranks = nan(numel(experiments) * 3, numel(trackers));

image_directory = fullfile(directory, 'images');
index_file = fullfile(directory, 'ranking.html');
temporary_index_file = fullfile(temporary_dir, 'index.tmp');
template_file = fullfile(fileparts(mfilename('fullpath')), 'report.html');

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


for i = 1:2:length(varargin)
    switch varargin{i}
        case 'CombineWeight'
            combine_weight = varargin{i+1}; 
        case 'LaTeXFile'
            latex_fid = varargin{i+1};
        case 'ReportTemplate'
            template_file = varargin{i+1};  
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

for e = 1:numel(experiments)

    experiment = experiments{e};

    print_text('Ranking analysis for experiment %s ...', experiment);

    print_indent(1);

    print_text('Loading data ...');

    [S_all, F_all, t_available] = ...
        process_results_labels(trackers, sequences, labels, experiment);

    S_all = cellfun(@(x) x(t_available, :), S_all, 'UniformOutput', 0);
    F_all = cellfun(@(x) x(t_available, :), F_all, 'UniformOutput', 0);
    
    print_text('Processing ...');

    % Start evaluation 
    type_comparison = 'Wilcoxon' ; % Wilcoxon, Prob_better
    alpha = 0.05 ;
    %alpha = 0.999;
    minimal_difference_acc = 0.0 ;
    minimal_difference_fail = 0 ;

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

    for l = 1:length(labels)
        label = labels{l};
        generate_ranking_plot(fullfile(image_directory, sprintf('ranking_%s_%s', experiment, label)), ...
        accuracy.ranks(l, :), robustness.ranks(l, :), sprintf('Experiment %s, label %s', experiment, label), ...
        t_labels(t_available), style(:, t_available), length(trackers));        
    end;
    
    generate_ranking_plot(fullfile(image_directory, sprintf('ranking_%s', experiment)), ...
        accuracy.average_ranks, robustness.average_ranks, sprintf('Experiment %s', experiment), ...
        t_labels(t_available), style(:, t_available), length(trackers));
    
    ranks(e * 3 - 2, t_available) = accuracy.average_ranks;
    ranks(e * 3 - 1, t_available) = robustness.average_ranks;
    ranks(e * 3, t_available) = accuracy.average_ranks * combine_weight + robustness.average_ranks * (1-combine_weight);
        
    fprintf(index_fid, '<h2>Experiment %s</h2>\n', experiment);
    
    fprintf(index_fid, '<p><img src="images/ranking_%s.png" alt="%s" /></p>\n', experiment, experiment);
 
    [~, order] = sort(ranks(e * 3, :), 'ascend');
    print_average_ranks(index_fid, ranks(e * 3, order), t_labels(order));

    report_file = fullfile(directory, sprintf('ranking-%s.html', experiment));
    
    fprintf(index_fid, '<a href="ranking-%s.html">More information</a>\n', experiment);
    
    generate_from_template(report_file, template_file, ...
        'body', fileread(temporary_file), 'title', sprintf('Ranking report for experiment %s', experiment), ...
        'timestamp', datestr(now, 31));

    delete(temporary_file);

end;

ranks(isnan(ranks)) = size(ranks, 2);

fprintf(index_fid, '<h2>Averaged</h2>\n');
mean_ranks = mean(ranks(3:3:end, :), 1);
[~, order] = sort(mean_ranks,'ascend')  ;
print_average_ranks(index_fid, mean_ranks(order), t_labels(order));

fclose(index_fid);

if ~isempty(latex_fid)

    ranks(end+1, :) = mean_ranks;
    
    ordered_ranks = ranks(:, order);

    fprintf(latex_fid, '\\begin{table}[h!]\\caption{Ranking results}\\label{tab:ranking}\n\\centering');

    ranking_labels = {'$R_A$', '$R_R$', '$R$'};

    prefix = [str2latex(sprintf([' & \\multicolumn{' num2str(length(ranking_labels)) '}{|c|}{ %s } '], experiments{:})), ' & '];
    
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

function generate_ranking_plot(filename, accuracy, robustness, plot_title, plot_labels, plot_style, plot_limit)

    hf = figure('Visible', 'off');

    hold on;
    grid on;
    title(plot_title,'interpreter','none');

    available = true(length(plot_labels), 1);

    for t = 1:length(plot_labels)

        if isnan(accuracy(t))
            available(t) = 0;
            continue;
        end;

        plot(robustness(t), accuracy(t), plot_style{1, t}, 'Color', plot_style{2, t},'MarkerSize',10,  'LineWidth', plot_style{3, t});

    end;
    legend(plot_labels(available), 'Location', 'NorthWestOutside'); 
    xlabel('Robustness rank'); set(gca,'XDir','Reverse');
    ylabel('Accuracy rank'); set(gca,'YDir','Reverse');
    xlim([1, plot_limit]); 
    ylim([1, plot_limit]);
    hold off;

    print( hf, '-dpng', '-r130', [filename, '.png']);

    box on;
    set(gca,'FontSize',12,'FontWeight','bold','linewidth',2);

    print( hf, '-depsc', [filename, '.eps']);
