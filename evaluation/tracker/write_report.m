function [report_file] = write_report(tracker, sequences, experiments, scores)

global track_properties;

report_file = fullfile(track_properties.directory, sprintf('%s-%s.html', tracker.identifier, datestr(now, 30)));

sequence_names = cellfun(@(x) x.name, sequences,'UniformOutput',false);

temporary_dir = tempdir;

temporary_file = fullfile(temporary_dir, 'tables.tmp');

fid = fopen(temporary_file, 'w');

for e = 1:length(experiments)
    
    fprintf(fid, '<h2>Experiment <em>%s</em></h2>\n', experiments{e});
    
    matrix2html(scores{e}', fid, 'rowLabels', {'accuracy', 'robustness', 'speed (fps)'}, 'columnLabels', sequence_names);
    
end;

fclose(fid);

template = fileread(fullfile(fileparts(mfilename('fullpath')), 'template.html'));

report = strrep(template, '{{body}}', fileread(temporary_file));

report = strrep(report, '{{tracker}}', tracker.identifier);

report = strrep(report, '{{timestamp}}', datestr(now, 31));

fid = fopen(report_file, 'w');

fwrite(fid, report);

fclose(fid);

delete(temporary_file);
