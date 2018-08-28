function [document, scores] = report_redetection(context, experiment, trackers, sequences, varargin)
% report_redetect Generate a report for redetection experiment
%
% Looks for the first failure and records how long it takes tracker to
% recover after it.
%
% Input:
% - context (structure): Report context structure.
% - experiment (struct): An experiment structure.
% - trackers (cell): An array of tracker structures.
% - sequences (cell): An array of sequence structures.
% - varargin[HideLegend] (boolean): Hide legend in plots.
%
% Output:
% - document (structure): Resulting document structure.
% - scores (struct): A scores structure.
%

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        otherwise
            error(['Unknown switch ', varargin{i}, '!']) ;
    end
end

if ~strcmp(experiment.type, 'unsupervised')
   error('Redetection analysis only suitable for unsupervised experiments!');
end

document = document_create(context, 'redetection', 'title', 'Redetection');

trackers_hash = md5hash(strjoin((cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');

sequences_hash = md5hash(strjoin((cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');

cache_identifier = sprintf('redetection_%s_%s_%s', experiment.name, trackers_hash, sequences_hash);

result = document_cache(context, cache_identifier, @analyze_redetection, experiment, trackers, ...
    sequences);

scores.name = 'Redetection';
scores.values = [nanmean(result.length, 2), mean(result.success,2)];
scores.ids = {'length', 'success'};
scores.names = {'Length', 'Success'};
scores.order = {'ascending', 'descending'};

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', 0);
sequence_labels = cellfun(@(x) x.name, sequences, 'UniformOutput', 0);

print_text('Writing report table ...');

document.section('Experiment %s', experiment.name);

table_data = cellfun(@(x, y) struct('text', sprintf('%d (%d%%)', x, y * 100), 'class', iff(isnan(x), 'bg-danger', iff(y == 1, 'bg-success', 'bg-warning'))), ...
    num2cell(result.length), num2cell(result.success), 'UniformOutput', false);

document.table(table_data, 'columnLabels', sequence_labels, 'rowLabels', tracker_labels, 'title', 'Redetection per sequence');

document.write();

end
