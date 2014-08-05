function [index_file, ranks] = ranking_analysis(context, trackers, sequences, experiments, varargin)

if length(trackers) < 2
	error('At least two trackers required for ranking analysis');
end

temporary_index_file = tempname;
template_file = fullfile(get_global_variable('toolkit_path'), 'templates', 'report.html');

labels = {};

ranks = nan(numel(experiments) * 3, numel(trackers));
scores = nan(numel(experiments) * 2, numel(trackers));
experiment_names = cellfun(@(x) x.name, experiments,'UniformOutput',false);
tracker_labels = cellfun(@(x) x.label, trackers, 'UniformOutput', 0);

index_fid = fopen(temporary_index_file, 'w');

combine_weight = 0.5 ;

latex_fid = [];
export_data = 0;

report_filename = sprintf('%sranking.html', context.prefix);

minimal_difference_acc = 0;
minimal_difference_fail = 0;
ar_plot = 0;
permutation_plot = 0;

permutation_args = {}; %'legend', 1, 'width' 4, 'height', 4};
ranking_permutation_args = {'flip', 1};

additional_trackers = {};

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
        case 'labels'
            labels = varargin{i+1} ;
        case 'permutationplot'
            permutation_plot = varargin{i+1} ;
        case 'exportdata'
            export_data = varargin{i+1} ;    
        case 'additionaltrackers'
            additional_trackers = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

if ~isempty(additional_trackers)
    ranks = nan(numel(experiments) * 3, numel(trackers) + numel(additional_trackers));
    scores = nan(numel(experiments) * 2, numel(trackers) + numel(additional_trackers));
    
    a_tracker_labels = ...
        cellfun(@(x) sprintf('<span style="color: red">%s</span>', x.label), additional_trackers, 'UniformOutput', 0);
    tracker_labels = cat(1, tracker_labels, a_tracker_labels);
end

for e = 1:numel(experiments)

    experiment = experiments{e};

    print_text('Ranking analysis for experiment %s ...', experiment.name);

    print_indent(1);

    print_text('Loading data ...');

	if isempty(labels)

		[S_all, F_all, available] = ...
		    process_results_sequences(trackers, convert_sequences(sequences, experiment.converter), experiment.name);

		series_labels = cellfun(@(x) x.name, sequences, 'UniformOutput', 0);

	else

		[S_all, F_all, available] = ...
		    process_results_labels(trackers, convert_sequences(sequences, experiment.converter), ...
		    labels, experiment.name);

		series_labels = labels;

	end

    S_all = cellfun(@(x) x(available, :), S_all, 'UniformOutput', 0);
    F_all = cellfun(@(x) x(available, :), F_all, 'UniformOutput', 0);
    
    print_text('Processing ...');

    [accuracy, robustness] = ranking(S_all, F_all, 'alpha', 0.05, ...
        'minimal_difference_acc', minimal_difference_acc,...
        'minimal_difference_fail', minimal_difference_fail) ;
    
    if ~isempty(additional_trackers)        
        %%% Additional trackers
        % Additional trackers will be ploted with regular trackers, but
        % ranks are computed only for regular trackers, otherwise
        % additional trackers would have changed the ranking.
        
        print_text('Loading data for additional trackers ...'); 
        
        % Get data for each frame in each sequence
        if isempty(labels)
            [additional_S_all, additional_F_all, additional_available] = ...
                    process_results_sequences(additional_trackers, ...
                    convert_sequences(sequences, experiment.converter), experiment.name);    
        else
            [additional_S_all, additional_F_all, additional_available] = ...
                process_results_labels(additional_trackers, convert_sequences(sequences, experiment.converter), ...
                labels, experiment.name);
        end
        
        % Remove unavailable trackers
        additional_S_all = cellfun(@(x) x(additional_available, :), additional_S_all, 'UniformOutput', 0);
        additional_F_all = cellfun(@(x) x(additional_available, :), additional_F_all, 'UniformOutput', 0);
        
        print_text('Comparing additional trackers with regular ones...'); 
        
        % Prepare tables
        a_trackers_num = length(additional_trackers);
        trackers_num = sum(available);
        sequences_num = length(sequences);

        additional_accuracy.mu = zeros(sequences_num, a_trackers_num);
        additional_accuracy.std = zeros(sequences_num, a_trackers_num);
        additional_accuracy.ranks = zeros(sequences_num, a_trackers_num);
        
        additional_robustness.mu = zeros(sequences_num, a_trackers_num);
        additional_robustness.std = zeros(sequences_num, a_trackers_num);
        additional_robustness.ranks = zeros(sequences_num, a_trackers_num);

        % Compute means for each sequence
        for seq_i = 1:sequences_num        
            S = additional_S_all{seq_i};
            validFrames = ~isnan(S);
            S(~validFrames) = 0;
            for t = 1 : a_trackers_num        
                additional_accuracy.mu(seq_i, t) = mean( S(t, validFrames(t, :)));
                additional_accuracy.std(seq_i, t) = std( S(t, validFrames(t, :)));

                additional_robustness.mu(seq_i, t) = mean(additional_F_all{seq_i}(t, :));
                additional_robustness.std(seq_i, t) = std(additional_F_all{seq_i}(t, :));
            end
        end
        
        % Compare trackers with regular ones
        for t = 1:a_trackers_num
                        
            tracker_acc_results = repmat(additional_accuracy.mu(:, t), 1, trackers_num);
            tracker_rob_results = repmat(additional_robustness.mu(:, t), 1, trackers_num);
            diff_acc_mat = accuracy.mu - tracker_acc_results;            
            diff_rob_mat = tracker_rob_results - robustness.mu;
            
            diff_acc_better = diff_acc_mat;
            diff_acc_better(diff_acc_better < 0) = nan;            
            diff_acc_worse = diff_acc_mat;
            diff_acc_worse(diff_acc_worse >= 0) = nan;
            
            diff_rob_better = diff_rob_mat;
            diff_rob_better(diff_rob_better < 0) = nan;            
            diff_rob_worse = diff_rob_mat;
            diff_rob_worse(diff_rob_worse >= 0) = nan;
            
            for s = 1:sequences_num 
                % Accuracy
                [val, pos] = min(diff_acc_better(s, :));                
                [val2, pos2] = max(diff_acc_worse(s, :));
                
                if isnan(val)
                    % Additional tracker is better than every other
                    rank_diff = accuracy.ranks(s, pos2) * abs(val2);
                    additional_accuracy.ranks(s, t) = ...
                        min(max(accuracy.ranks(s, pos2) - rank_diff, 1), trackers_num);
                    
                elseif isnan(val2)
                    % Additional tracker is worse than every other
                    rank_diff = accuracy.ranks(s, pos) * val;
                    additional_accuracy.ranks(s, t) = ...
                        min(max(accuracy.ranks(s, pos) + rank_diff, 1), trackers_num);
                else                
                    percentage = abs(val2)/(val + abs(val2));
                    rank_diff = accuracy.ranks(s, pos2) - accuracy.ranks(s, pos);
                    additional_accuracy.ranks(s, t) = ...
                        min(max(accuracy.ranks(s, pos) + (rank_diff*percentage), 1), trackers_num);  
                end
                
                % Robustness
                [val, pos] = min(diff_rob_better(s, :));
                [val2, pos2] = max(diff_rob_worse(s, :));
                
                if val == 0
                    % Regular tracker with same robustness found
                    additional_robustness.ranks(s, t) = robustness.ranks(s, pos);
                elseif isnan(val)
                    % Additional tracker is better than every other
                    rank_diff = robustness.ranks(s, pos2) * abs(val2);
                    additional_robustness.ranks(s, t) = ...
                        min(max(robustness.ranks(s, pos2) - rank_diff, 1), trackers_num);
                elseif isnan(val2)
                    % Additional tracker is worse than every other
                    rank_diff = robustness.ranks(s, pos) * val;
                    additional_robustness.ranks(s, t) = ...
                        min(max(robustness.ranks(s, pos) + rank_diff, 1), trackers_num);
                else
                    percentage = abs(val2)/(val + abs(val2));
                    rank_diff = robustness.ranks(s, pos2) - robustness.ranks(s, pos);
                    additional_robustness.ranks(s, t) = ...
                        min(max(robustness.ranks(s, pos) + (rank_diff*percentage), 1), trackers_num);
                end                
            end                   
        end
        
        additional_accuracy.average_ranks = mean(additional_accuracy.ranks, 1);
        additional_robustness.average_ranks = mean(additional_robustness.ranks, 1);
    end    
    
    if export_data
        
        save(fullfile(context.data, sprintf('%s_ranks.mat', experiment.name)), 'accuracy', 'robustness');
        
    end;          
    
    print_indent(-1);

    print_text('Writing report ...');

    if isempty(additional_trackers) 
        report_file = generate_ranking_report(context, trackers(available), experiment, accuracy, robustness, ...
             'SeriesLabels', series_labels, 'combineWeight', combine_weight, 'reporttemplate', template_file, ...
             'arplot', ar_plot, 'permutationplot', permutation_plot);
    else
        report_file = generate_ranking_report(context, trackers(available), experiment, accuracy, robustness, ...
             'SeriesLabels', series_labels, 'combineWeight', combine_weight, 'reporttemplate', template_file, ...
             'arplot', ar_plot, 'permutationplot', permutation_plot, ...
             'additionaltrackers', {additional_trackers(additional_available), additional_accuracy, additional_robustness}); 
    end
    
    fprintf(index_fid, '<h2>Experiment %s</h2>\n', experiment.name);
    
    if ~isempty(additional_trackers)
       accuracy.average_ranks = cat(2, accuracy.average_ranks, additional_accuracy.average_ranks);
       robustness.average_ranks = cat(2, robustness.average_ranks, additional_robustness.average_ranks);
       
       accuracy.mu = cat(2, accuracy.mu, additional_accuracy.mu);
       robustness.mu = cat(2, robustness.mu, additional_robustness.mu);
       
       accuracy.std = cat(2, accuracy.std, additional_accuracy.std);
       robustness.std = cat(2, robustness.std, additional_robustness.std);
       
       accuracy.ranks = cat(2, accuracy.ranks, additional_accuracy.ranks);
       robustness.ranks = cat(2, robustness.ranks, additional_robustness.ranks);
       
       available = cat(1, available, additional_available);
    end
    
    ranks(e * 3 - 2, available) = accuracy.average_ranks;
    ranks(e * 3 - 1, available) = robustness.average_ranks;
    ranks(e * 3, available) = accuracy.average_ranks * combine_weight + robustness.average_ranks * (1-combine_weight);
    
    scores(e * 2 - 1, available) = mean(accuracy.mu);
    scores(e * 2, available) = mean(robustness.mu);
    
    [~, order] = sort(ranks(e * 3, :), 'ascend');
    print_average_ranks(index_fid, ranks(e * 3, order), tracker_labels(order));
    
    fprintf(index_fid, '<a href="%s" class="more">More information</a>\n', report_file);

end;

ranks(isnan(ranks)) = size(ranks, 2);

fprintf(index_fid, '<h2>Averaged</h2>\n');
mean_ranks = mean(ranks(3:3:end, :), 1);
[~, order] = sort(mean_ranks,'ascend')  ;
print_average_ranks(index_fid, mean_ranks(order), tracker_labels(order));

if permutation_plot

    fprintf(index_fid, '<h2>Ranking permutations</h2>\n');    
            
    h = generate_permutation_plot(trackers, ranks(1:3:end, :), experiment_names, ...
        permutation_args{:}, ranking_permutation_args{:}, 'additionaltrackers', additional_trackers);
    
    insert_figure(context, index_fid, h, 'permutation_accuracy', 'Ranking permutations for accuracy rank');
    
    if export_data
        insert_figure(context, 0, h, 'permutation_accuracy', 'Ranking permutations for accuracy rank', 'format', 'data');
    end;    
    
    h = generate_permutation_plot(trackers, ranks(2:3:end, :), experiment_names, ...
        permutation_args{:}, ranking_permutation_args{:}, 'additionaltrackers', additional_trackers);

    insert_figure(context, index_fid, h, 'permutation_robustness', 'Ranking permutations for robustness rank');
            
    if export_data
        insert_figure(context, 0, h, 'permutation_robustness', 'Ranking permutations for robustness rank', 'format', 'data');
    end;      
%     
% %--   
%   
%     h = generate_permutation_plot(trackers, scores(1:2:end, :), experiment_names, permutation_args{:}, 'scope', [0, 1], 'type', 'Accuracy');
% 
%     insert_figure(context, index_fid, h, 'permutation_accuracy_raw', 'Scores permutations for accuracy rank');
%     
%     if export_data
%         insert_figure(context, 0, h, 'permutation_accuracy_raw', 'Scores permutations for accuracy rank', 'format', 'data');
%     end;    
%     
%     h = generate_permutation_plot(trackers, scores(2:2:end, :), experiment_names, permutation_args{:}, 'scope', [0, max(max(scores(2:2:end, :)))+1], 'type', 'Robustness');
% 
%     insert_figure(context, index_fid, h, 'permutation_robustness_raw', 'Scores permutations for robustness rank');
%             
%     if export_data
%         insert_figure(context, 0, h, 'permutation_robustness_raw', 'Scores permutations for robustness rank', 'format', 'data');
%     end; 
% 
% 
% %--
    
    h = generate_permutation_plot(trackers, ranks(3:3:end, :), experiment_names, ...
        permutation_args{:}, ranking_permutation_args{:}, 'additionaltrackers', additional_trackers); 
    
    insert_figure(context, index_fid, h, 'permutation_combined', 'Ranking permutations for combined rank');
    
    if export_data
        insert_figure(context, 0, h, 'permutation_combined', 'Ranking permutations for combined rank', 'format', 'data');       
    end;      
    
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
    
    matrix2latex(celldata, latex_fid, 'columnLabels', column_labels, 'rowLabels', strrep(tacker_labels(order), '_', '\_'), 'format', '%.2f', ...
            'prefix', prefix);

    fprintf(latex_fid, '\\end{table}\n');

end;

index_file = report_filename;

generate_from_template(fullfile(context.root, index_file), template_file, ...
    'body', fileread(temporary_index_file), 'title', 'Ranking report', ...
    'timestamp', datestr(now, 31));

delete(temporary_index_file);

function print_average_ranks(fid, ranks, tacker_labels )

    table = cellfun(@(x) sprintf('%1.3g', x), num2cell(ranks), 'UniformOutput', 0);

    fprintf(fid, '<div class="table">');
    
    matrix2html(table, fid, 'columnLabels', tacker_labels);

    fprintf(fid, '</div>');

