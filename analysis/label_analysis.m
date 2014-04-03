function [index_file] = label_analysis(directory, trackers, sequences, experiments, labels, varargin)

temporary_dir = tempdir;

index_file = fullfile(directory, 'labels.html');
temporary_index_file = fullfile(temporary_dir, 'index.tmp');
template_file = fullfile(get_global_variable('toolkit_path'), 'templates', 'report.html');

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'latexfile'
            latex_fid = varargin{i+1};
        case 'reporttemplate'
            template_file = varargin{i+1};           
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

index_fid = fopen(temporary_index_file, 'w');

scores = zeros(length(labels), numel(experiments)*2);

for e = 1:numel(experiments)

    experiment = experiments{e};

    print_text('Label analysis for experiment %s ...', experiment.name);

    print_indent(1);

    print_text('Loading data ...');

    [S_all, F_all, t_available] = ...
        process_results_labels(trackers, convert_sequences(sequences, ...
        experiment.converter), labels, experiment.name);

    S_all = cellfun(@(x) x(t_available, :), S_all, 'UniformOutput', 0);
    F_all = cellfun(@(x) x(t_available, :), F_all, 'UniformOutput', 0);

    print_text('Processing ...');

    for l = 1:length(labels)
        
        accuracy = S_all{l};
        failures = F_all{l};
        
        scores(l, e*2-1) = median(nanmean(accuracy, 2));
        scores(l, e*2) = median(nanmean(failures, 2));
        
    end;

    print_indent(-1);

end;

c_labels = cell(length(experiments)*2, 1);
for i = 1:length(experiments)
    c_labels{i*2-1} = sprintf('Accuracy %s', experiments{i});
    c_labels{i*2} = sprintf('Failures %s', experiments{i});
end;

matrix2html(scores, index_fid, 'columnLabels', c_labels, 'rowLabels', labels);

generate_from_template(index_file, template_file, ...
    'body', fileread(temporary_index_file), 'title', 'Label analysis report', ...
    'timestamp', datestr(now, 31));

if ~isempty(latex_fid)

    fprintf(latex_fid, '\\begin{table}[h!]\\caption{Label difficulty}\\label{tab:labels}\n\\centering');
    
    matrix2latex(scores', latex_fid, 'rowLabels', c_labels, 'columnLabels', strrep(labels, '_', '\_'), 'format', '%.2f');
    
    fprintf(latex_fid, '\\end{table}\n');    

end;
