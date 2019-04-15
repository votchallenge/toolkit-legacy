function [document, scores] = report_speed(context, experiment, trackers, sequences, varargin)
% report_speed Generate an overview of tracker implementations
%
% Generate an overview of trackers computational performance and
% implementational details.
%
% Input:
% - context (structure): Report context structure.
% - experiment (struct): An experiment structure.
% - trackers (cell): An array of tracker structures.
% - sequences (cell): An array of sequence structures.
%
% Output:
% - document (structure): Resulting document structure.
%

document = document_create(context, 'speed', 'title', ['Speed report for experiment ', experiment.name]);

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        otherwise
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

sequences_hash = md5hash(strjoin(sort(cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');
trackers_hash = md5hash(strjoin(sort(cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');

cache_identifier = sprintf('speed_%s_%s_%s.mat', experiment.name, trackers_hash, sequences_hash);

speed = document_cache(context, cache_identifier, @analyze_speed, experiment, trackers, sequences, 'cache', context.cachedir);

averaged_normalized = squeeze(mean(speed.normalized, 3));
averaged_original = squeeze(mean(speed.original, 3));

scores.name = 'Speed';
if ~all(isnan(speed.normalized(:)))
    scores.values = cat(2, averaged_normalized', averaged_original');
    scores.ids = {'normalized', 'original'};
    scores.names = {'Normalized', 'FPS'};
    scores.order = {'descending', 'descending'};
else
    scores.values = averaged_original';
    scores.ids = {'original'};
    scores.names = {'FPS'};
    scores.order = {'descending'};
end

tracker_labels = cellfun(@(x) x.label, trackers, 'UniformOutput', false);
column_labels = cat(2, cellfun(@(x) x.name, sequences, 'UniformOutput', false), {'Average'});

document.subsection('Raw FPS');

tabledata = num2cell(cat(2, reshape(squeeze(speed.original), numel(trackers), numel(sequences)), averaged_original'));
tabledata = highlight_best_rows(tabledata, repmat({'descend'}, 1, numel(sequences)+1));

document.table(tabledata, 'columnLabels', column_labels, 'rowLabels', tracker_labels);

if ~all(isnan(speed.normalized(:)))

    document.subsection('Normalized (EFO)');

    tabledata = num2cell(cat(2, reshape(squeeze(speed.normalized), numel(trackers), numel(sequences)), averaged_normalized'));
    tabledata = highlight_best_rows(tabledata, repmat({'descend'}, 1, numel(sequences)+1));

    document.table(tabledata, 'columnLabels', column_labels, 'rowLabels', tracker_labels);
end;

document.write();

end

