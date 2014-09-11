function report_official(context, experiments, trackers, sequences, varargin)

html_template_file = fullfile(get_global_variable('toolkit_path'), 'templates', 'report.html');
latex_template_file = fullfile(get_global_variable('toolkit_path'), 'templates', 'report.tex');

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'latextemplate'
            latex_template_file = varargin{i+1};
        case 'htmltemplate'
            html_template_file = varargin{i+1}; 
        case 'arplot'
            ar_plot = varargin{i+1};
        case 'permutationplot'
            permutation_plot = varargin{i+1};
        case 'exportdata'
            export_data = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end 

set_global_variable('matlab_startup_model', [923.5042, -4.2525]);

report = create_report('VOT competition report', 'latex');

print_indent(-1);

%load(fullfile(fileparts(mfilename('fullpath')), 'data.mat'));
%ttr = trackers;

%load(fullfile(context.root, 'data.mat'));

%trackers = ttr;

%h = generate_trackers_legend(trackers, 10, 8);
%insert_figure(context, report.fid, h, 'legend', 'Legend', 'format', 'latex');   

%return;

print_text('Speed analysis ...'); print_indent(1);

[speeds, normalized] = analyze_speed(experiments, trackers, sequences);

averaged_speed = squeeze(mean(mean(speeds, 3), 1));
averaged_normalized = squeeze(all(all(normalized, 3), 1));

averaged_speed(~averaged_normalized) = nan;

print_indent(-1);

print_text('Ranking analysis ...'); print_indent(1);

labels = {'camera_motion', 'illum_change', 'occlusion', 'size_change', ...
    'motion_change', 'empty'};
[ranks, scores] = analyze_ranks(experiments, trackers, sequences, 'labels', labels, 'usepractical', true);

averaged_ranks = squeeze(mean(ranks, 2));
averaged_scores = squeeze(mean(scores, 2));

ratio = 0.5;

combined_ranks = ratio * averaged_ranks(:, :, 1) + (1 - ratio) * averaged_ranks(:, :, 2);


%save(fullfile(context.root, 'data.mat'), 'ranks', 'scores', 'trackers', 'speeds', 'normalized');
%return;

overall_ranks = mean(combined_ranks, 1);
[~, order] = sort(overall_ranks,'ascend')  ;

experiment_names = cellfun(@(x) x.name, experiments,'UniformOutput',false);
tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', 0);

fprintf(report.fid, '\\begin{table}[h!]\\caption{Ranking results}\\label{tab:ranking}\n\\centering');

ranking_labels = {'$R_A$', '$R_R$', '$R$'};

column_labels = [ranking_labels(repmat(1:length(ranking_labels), 1, numel(experiments))), {'$R_{\Sigma}$', 'Speed', 'Impl.'}];

prefix = [str2latex(sprintf([' & \\multicolumn{' num2str(length(ranking_labels)) '}{|c|}{ %s } '], experiment_names{:})), ' & & & '];

experiments_ranking_data = zeros(3 * numel(experiments), numel(trackers));
experiments_ranking_data(1:3:end) = averaged_ranks(:, :, 1);
experiments_ranking_data(2:3:end) = averaged_ranks(:, :, 2);
experiments_ranking_data(3:3:end) = combined_ranks;
experiments_ranking_data = num2cell(experiments_ranking_data);

overall_ranking_data = num2cell(overall_ranks);
speed_data = num2cell(averaged_speed);

%implementation_data = cell(size(trackers));
%for e = 1:length(trackers)
%	if 
%end;

implementation_data = cellfun(@(x) x.metadata.implementation, trackers, 'UniformOutput', 0, 'ErrorHandler', @(e, x) 'unknown')';

tabledata = cat(1, experiments_ranking_data, overall_ranking_data, speed_data, implementation_data)';

ordering = [repmat({'ascending'}, 1, numel(experiments) * 3 + 1), 'descending', 'none'];

tabledata = highlight_best_rows(tabledata, ordering);

matrix2latex(tabledata(order, :), report.fid, 'columnLabels', column_labels, 'rowLabels', tracker_labels(order), 'format', '%.2f', ...
        'prefix', prefix);

fprintf(report.fid, '\\end{table}\n');


for e = 1:length(experiments)

    report.section('Experiment %s', experiments{e}.name);
    
    plot_title = sprintf('Ranking plot for experiment %s', experiments{e}.name);
    plot_id = sprintf('rankingplot_%s', experiments{e}.name);
    
    plot_title = str2latex(plot_title);
    plot_id = strrep(plot_id, '_', '-');
    
    hf = generate_ranking_plot(trackers, squeeze(averaged_ranks(e, :, 1)), ...
        squeeze(averaged_ranks(e, :, 2)), ...
        plot_title, numel(trackers));

    insert_figure(context, report.fid, hf, plot_id, plot_title, 'format', 'latex');
    
    
    for l = 1:length(labels)
        
        plot_title = sprintf('Ranking plot for label %s in experiment %s', labels{l}, experiments{e}.name);
        plot_id = sprintf('rankingplot_%s_%s', experiments{e}.name, labels{l});

        plot_title = str2latex(plot_title);
        plot_id = strrep(plot_id, '_', '-');

        hf = generate_ranking_plot(trackers, squeeze(ranks(e, l, :, 1)), ...
            squeeze(ranks(e, l, :, 2)), ...
            plot_title, numel(trackers));

        insert_figure(context, report.fid, hf, plot_id, plot_title, 'format', 'latex');   
        
    end;
    
end;

report.write(fullfile(context.root, 'report.tex'));
