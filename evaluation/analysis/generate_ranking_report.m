function [index_file, ranks] = generate_ranking_report(context, trackers, experiment, accuracy, robustness, varargin)

temporary_index_file = tempname;
template_file = fullfile(fileparts(mfilename('fullpath')), 'report.html');

labels = [];
ar_plot = 0;
permutation_plot = 0;
combine_weight = 0.5 ;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'reporttemplate'
            template_file = varargin{i+1};         
        case 'combineweight'
            combine_weight = varargin{i+1};    
        case 'labels'
            labels = varargin{i+1};   
        case 'arplot'
            ar_plot = varargin{i+1} ;
        case 'permutationplot'
            permutation_plot = varargin{i+1} ;               
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

fid = fopen(temporary_index_file, 'w');

tracker_labels = cellfun(@(x) x.label, trackers, 'UniformOutput', 0);

if isempty(labels)
    labels = cellfun(@(x) sprintf('Series %d', x), {1:size(accuracy, 1)}, 'UniformOutput', 0);
end;

t_labels_acc = tracker_labels;
t_labels_rob = tracker_labels;
t_labels_merg = tracker_labels;

merged_ranks = accuracy.average_ranks * combine_weight + robustness.average_ranks * (1 - combine_weight);
ranks = struct('combined', merged_ranks, 'accuracy', accuracy.average_ranks, 'robustness', robustness.average_ranks);

accuracy_ranks = accuracy.ranks;
robustness_ranks = robustness.ranks;
combined_ranks = accuracy.ranks * combine_weight + robustness.ranks * (1-combine_weight);

average_accuracy_ranks = accuracy.average_ranks;
average_robustness_ranks = robustness.average_ranks;

% sort accuracy and robustness by their average ranks
[~, order_by_ranks_acc]  =  sort(accuracy.average_ranks,'ascend')  ;
accuracy.mu = accuracy.mu(:,order_by_ranks_acc) ;
accuracy.std = accuracy.std(:,order_by_ranks_acc) ;
accuracy.ranks = accuracy.ranks(:,order_by_ranks_acc) ;
accuracy.average_ranks = accuracy.average_ranks(order_by_ranks_acc) ;
t_labels_acc = t_labels_acc(order_by_ranks_acc) ;

[~, order_by_ranks_rob] = sort(robustness.average_ranks,'ascend')  ;
robustness.mu = robustness.mu(:,order_by_ranks_rob) ;
robustness.std = robustness.std(:,order_by_ranks_rob) ;
robustness.ranks = robustness.ranks(:,order_by_ranks_rob) ;
robustness.average_ranks = robustness.average_ranks(order_by_ranks_rob) ;  
t_labels_rob = t_labels_rob(order_by_ranks_rob) ;

[~, order_by_ranks_merg] = sort(merged_ranks,'ascend')  ;
t_labels_merg = t_labels_merg(order_by_ranks_merg) ;    
merged_ranks = merged_ranks(order_by_ranks_merg);

fprintf(fid, '<h2>Accuracy</h2>\n');

print_tables(fid, accuracy, t_labels_acc, labels ) ;

if permutation_plot
    h = generate_permutation_plot(trackers, accuracy_ranks, labels);
    insert_figure(context, fid, h, sprintf('permutation_accuracy_%s', experiment.name), ...
        'Ranking permutations for accuracy rank');
end;

fprintf(fid, '<h2>Robustness</h2>\n');

print_tables(fid, robustness, t_labels_rob, labels );
 
if permutation_plot
    h = generate_permutation_plot(trackers, robustness_ranks, labels);
    insert_figure(context, fid, h, sprintf('permutation_robustness_%s', experiment.name), ...
        'Ranking permutations for robustness rank');
end;
    
fprintf(fid, '<h2>Combined ranking (weight = %1.3g)</h2>\n', combine_weight);

print_average_ranks(fid, merged_ranks, t_labels_merg );

if permutation_plot
    h = generate_permutation_plot(trackers, combined_ranks, labels);
    insert_figure(context, fid, h, sprintf('permutation_combined_%s', experiment.name), ...
        'Ranking permutations for combined rank');    
end;

if ar_plot

%     for l = 1:length(labels)
%         label = labels{l};
%         h = generate_ranking_plot(trackers(available), accuracy.ranks(l, :), robustness.ranks(l, :), ...
%             sprintf('Experiment %s, label %s', experiment.name, label), length(trackers));
% 
%         export_figure(h, fullfile(context.images, sprintf('ranking_%s_%s', experiment.name, label)), 'png');
%     end;

    h = generate_ranking_plot(trackers, average_accuracy_ranks, average_robustness_ranks, ...
        sprintf('Experiment %s', experiment.name), length(trackers));

    insert_figure(context, fid, h, sprintf('ranking_%s', experiment.name), ...
        sprintf('Ranking AR-plot for %s', experiment.name));        

end;



index_file = sprintf('%sranking-%s.html', context.prefix, experiment.name);

generate_from_template(fullfile(context.root, index_file), template_file, ...
    'body', fileread(temporary_index_file), 'title', sprintf('Ranking report for experiment %s', experiment.name), ...
    'timestamp', datestr(now, 31));

delete(temporary_index_file);

% --------------------------------------------------------------------- %
function print_tables(fid, in_table, t_labels, s_labels )

N_trackers = size(in_table.mu, 2) ;
N_sequences = size(in_table.mu, 1) ;

fprintf(fid, '<h3>Raw results</h3>\n');

table = cell(N_sequences, N_trackers);

for s = 1 : N_sequences
    for t = 1 : (N_trackers)
        table{s, t} = sprintf('%1.3g (%1.3g)', in_table.mu(s,t),  in_table.std(s,t) ) ;        
    end   
end

fprintf(fid, '<div class="table">');

matrix2html(table, fid, 'columnLabels', t_labels, 'rowLabels', s_labels);

fprintf(fid, '</div>');

fprintf(fid, '<h3>Ranks</h3>\n');

table = cell(N_sequences + 1, N_trackers);

for t = 1 : N_trackers
    for s = 1 : N_sequences    
        table{s, t} = sprintf('%1.3g', in_table.ranks(s, t)) ;     
    end
    table{end, t} = sprintf('%1.3g', in_table.average_ranks(t)) ;     
end

s_labels{end+1} = '<em>Average</em>';

fprintf(fid, '<div class="table">');

matrix2html(table, fid, 'columnLabels', t_labels, 'rowLabels', s_labels);

fprintf(fid, '</div>');

%fprintf(fid, '<h3>Average ranks</h3>\n');
%print_average_ranks(fid, in_table.average_ranks(:)', t_labels );

% --------------------------------------------------------------------- %
function print_average_ranks(fid, ranks, t_labels )

table = cellfun(@(x) sprintf('%1.3g', x), num2cell(ranks), 'UniformOutput', 0);

fprintf(fid, '<div class="table">');
    
matrix2html(table, fid, 'columnLabels', t_labels);

fprintf(fid, '</div>');