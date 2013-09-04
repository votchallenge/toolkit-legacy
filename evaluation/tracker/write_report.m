function [report_file] = write_report(tracker, sequences, experiments, scores)

global track_properties;

report_file = fullfile(track_properties.directory, sprintf('%s-%s.html', tracker.identifier, datestr(now, 30)));

table_file = fullfile(track_properties.directory, sprintf('%s-%s.tex', tracker.identifier, datestr(now, 30)));

sequence_names = cellfun(@(x) x.name, sequences,'UniformOutput',false);

temporary_dir = tempdir;

temporary_file = fullfile(temporary_dir, 'tables.tmp');

html_fid = fopen(temporary_file, 'w');

latex_fid = fopen(table_file, 'w');

for e = 1:length(experiments)
    
    fprintf(html_fid, '<h2>Experiment <em>%s</em></h2>\n', experiments{e});

    fprintf(latex_fid, '\\begin{table}[h]\\caption{Experiment %s}\\label{tab:results-%s}\n', strrep(experiments{e}, '_', '\_'), strrep(experiments{e}, '_', '-'));

    matrix2html(scores{e}, html_fid, 'columnLabels', {'accuracy', 'robustness', 'speed (fps)'}, 'rowLabels', sequence_names);

    matrix2latex(scores{e}, latex_fid, 'columnLabels', {'accuracy', 'robustness', 'speed (fps)'}, 'rowLabels', strrep(sequence_names, '_', '\_'), 'format', '%.2f');

    fprintf(latex_fid, '\\end{table}\n');

end;

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
