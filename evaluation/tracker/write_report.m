function [report_file] = write_report(name, tracker, sequences, experiments, scores)

global track_properties;

directory = fullfile(track_properties.directory, 'reports', name);

mkpath(directory);

report_file = fullfile(directory, sprintf('%s.html', tracker.identifier));

table_file = fullfile(directory, sprintf('%s.tex', tracker.identifier));

sequence_names = cellfun(@(x) x.name, sequences,'UniformOutput',false);

experiment_names = cellfun(@(x) x.name, experiments,'UniformOutput',false);

temporary_dir = tempdir;

temporary_file = fullfile(temporary_dir, 'tables.tmp');

html_fid = fopen(temporary_file, 'w');

latex_fid = fopen(table_file, 'w');

measure_labels = {'accuracy', 'robustness', 'speed (fps)'};

fprintf(latex_fid, '%% Per-experiment tables \n\n');

for e = 1:length(experiments)
    
    fprintf(html_fid, '<h2>Experiment <em>%s</em></h2>\n', experiments{e}.name);

    fprintf(latex_fid, '\\begin{table}[h!]\\caption{Experiment {\\em %s} results for tracker {\\em %s} }\\label{tab:results-%s-%s}\n\\centering', ...
			str2latex(experiments{e}.name), str2latex(tracker.identifier), strrep(experiments{e}.name, '_', '-'), strrep(tracker.identifier, '_', '-'));

    matrix2html(scores{e}, html_fid, 'columnLabels', measure_labels, 'rowLabels', sequence_names);

    matrix2latex(scores{e}, latex_fid, 'columnLabels', measure_labels, 'rowLabels', strrep(sequence_names, '_', '\_'), 'format', '%.2f');

    fprintf(latex_fid, '\\end{table}\n');

end;

fprintf(latex_fid, '\n\n%% Single results table \n\n');

fprintf(latex_fid, '\\begin{table}[h!]\\caption{Results for tracker {\\em %s}}\\label{tab:results}\n\\centering', ...
		str2latex(tracker.identifier));

matrix2latex([scores{:}], latex_fid, 'columnLabels', measure_labels(repmat(1:length(measure_labels), ...
		1, numel(scores))), 'rowLabels', strrep(sequence_names, '_', '\_'), 'format', '%.2f', ...
		'prefix', str2latex(sprintf([' & \\multicolumn{' num2str(length(measure_labels)) '}{|c|}{ %s } '], experiment_names{:})));

fprintf(latex_fid, '\\end{table}\n');

fclose(html_fid);

fclose(latex_fid);

template = fileread(fullfile(fileparts(mfilename('fullpath')), 'template.html'));

report = strrep(template, '{{body}}', fileread(temporary_file));

report = strrep(report, '{{tracker}}', tracker.identifier);

report = strrep(report, '{{timestamp}}', datestr(now, 31));

fid = fopen(report_file, 'w');

fwrite(fid, report);

fclose(fid);

delete(temporary_file);
