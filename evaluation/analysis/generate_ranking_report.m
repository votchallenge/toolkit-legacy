function [ranks] = generate_ranking_report(filename, accuracy, robustness, varargin)

tracker_labels = [];
sequence_labels = [];

combine_weight = 0.5 ;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'combineweight'
            combine_weight = varargin{i+1}; 
        case 'trackerlabels'
            tracker_labels = varargin{i+1};   
        case 'sequencelabels'
            sequence_labels = varargin{i+1};             
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

if (ischar(filename))
    fid = fopen(filename, 'w');
    close_file = 1;
else
    fid = filename;
    close_file = 0;
end;

if isempty(tracker_labels)
    tracker_labels = cellfun(@(x) sprintf('Tracker %d', x), {1:size(accuracy, 2)}, 'UniformOutput', 0);
end;

if isempty(sequence_labels)
    sequence_labels = cellfun(@(x) sprintf('Sequence %d', x), {1:size(accuracy, 1)}, 'UniformOutput', 0);
end;

t_labels_acc = tracker_labels;
t_labels_rob = tracker_labels;
t_labels_merg = tracker_labels;

merged_ranks = accuracy.average_ranks * combine_weight + robustness.average_ranks * (1-combine_weight);
ranks = struct('combined', merged_ranks, ...
    'accuracy', accuracy.average_ranks, 'robustness', ...
    robustness.average_ranks);

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

print_tables(fid, accuracy, t_labels_acc, sequence_labels ) ;

fprintf(fid, '<h2>Robustness</h2>\n');

print_tables(fid, robustness, t_labels_rob, sequence_labels );
 
fprintf(fid, '<h2>Combined ranking (weight = %1.3g)</h2>\n', combine_weight);

print_average_ranks(fid, merged_ranks, t_labels_merg );

if (close_file)
    fclose(fid);
end;

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

matrix2html(table, fid, 'columnLabels', t_labels, 'rowLabels', s_labels);

fprintf(fid, '<h3>Ranks</h3>\n');

table = cell(N_sequences, N_trackers);

for s = 1 : N_sequences
    for t = 1 : (N_trackers)
        table{s, t} = sprintf('%1.3g', in_table.ranks(s, t)) ;     
    end   
end

matrix2html(table, fid, 'columnLabels', t_labels, 'rowLabels', s_labels);

fprintf(fid, '<h3>Average ranks</h3>\n');

print_average_ranks(fid, in_table.average_ranks(:)', t_labels );

% --------------------------------------------------------------------- %
function print_average_ranks(fid, ranks, t_labels )

table = cellfun(@(x) sprintf('%1.3g', x), num2cell(ranks), 'UniformOutput', 0);

matrix2html(table, fid, 'columnLabels', t_labels);

