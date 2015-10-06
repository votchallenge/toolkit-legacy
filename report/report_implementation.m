function [document] = report_implementation(context, trackers, sequences, experiments, varargin)
% report_speed Generate an overview of tracker implementations
%
% Generate an overview of trackers computational performance and
% implementational details.
%
% Input:
% - context (structure): Report context structure.
% - trackers (cell): An array of tracker structures.
% - sequences (cell): An array of sequence structures.
% - experiments (cell): An array of experiment structures.
%
% Output:
% - document (structure): Resulting document structure.
%

document = create_document(context, 'implementation', 'title', 'Implementational details');

for i = 1:2:length(varargin)
    switch lower(varargin{i})         
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

print_text('Speed analysis ...'); print_indent(1);

experiments_hash = md5hash(strjoin(sort(cellfun(@(x) x.name, experiments, 'UniformOutput', false)), '-'), 'Char', 'hex');
sequences_hash = md5hash(strjoin(sort(cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');
trackers_hash = md5hash(strjoin(sort(cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');

cache_identifier = sprintf('speed_%s_%s_%s.mat', experiments_hash, trackers_hash, sequences_hash);

speed = report_cache(context, cache_identifier, @analyze_speed, experiments, trackers, sequences, 'cache', context.cachedir);

averaged_normalized = squeeze(mean(mean(speed.normalized, 3), 1));
averaged_original = squeeze(mean(mean(speed.original, 3), 1));

print_indent(-1);

tracker_labels = cellfun(@(x) iff(isfield(x.metadata, 'verified') && x.metadata.verified, [x.label, '*'], x.label), trackers, 'UniformOutput', false);

column_labels = {'Normalized speed', 'Raw speed', 'Platform', 'Interpreter', 'Environment', 'Deterministic', 'Complete', 'TraX'};

tabledata = cell(numel(trackers), 8);

tabledata(:, 1) = num2cell(averaged_normalized);
tabledata(:, 2) = num2cell(averaged_original);
tabledata(:, 3) = cellfun(@get_platform, trackers, 'UniformOutput', false);
tabledata(:, 4) = cellfun(@get_interpreter, trackers, 'UniformOutput', false);
tabledata(:, 5) = cellfun(@get_environment, trackers, 'UniformOutput', false);
tabledata(:, 8) = cellfun(@(x) iff(x.trax, 'Yes', 'No'), trackers, 'UniformOutput', false);

print_text('Gathering other information ...');

for t = 1:numel(trackers)
    cache_identifier = sprintf('result_analysis_%s_%s.mat', trackers{t}.identifier, sequences_hash);
    aggregated.completed = true;
    aggregated.deterministic = true;
    aggregated = report_cache(context, cache_identifier, @iterate, experiments, ...
        trackers{t}, sequences, 'iterator', @aggregate_iterator, 'context', aggregated);
    tabledata{t, 6} = iff(aggregated.deterministic, 'Yes', 'No');
    tabledata{t, 7} = iff(aggregated.completed, 'Yes', 'No');
end;

tabledata(:, 1:2) = highlight_best_rows(tabledata(:, 1:2),  {'descend', 'descend'});
document.table(tabledata, 'columnLabels', column_labels, 'rowLabels', tracker_labels);
document.write();

end

function platform = get_platform(tracker)

    if isfield(tracker, 'metadata') && isfield(tracker.metadata, 'platform')
        platform = tracker.metadata.platform;
    else
        platform = '';
    end
end

function interpreter = get_interpreter(tracker)

    if isfield(tracker, 'interpreter')
        interpreter = tracker.interpreter;
    else
        interpreter = '';
    end
end

function envirionment = get_environment(tracker)

    if isfield(tracker.metadata, 'environment')
        envirionment = tracker.metadata.environment;
    else
        envirionment = 'unknown';
    end
end

function context = aggregate_iterator(event, context)

    switch (event.type)
        case 'experiment_enter'
      
        case 'experiment_exit'

        case 'tracker_enter'
            
        case 'tracker_exit'

        case 'sequence_enter'
            
            execution_parameters = struct();
            if isfield(event.experiment, 'parameters')
                execution_parameters = event.experiment.parameters;
            end;
            
            sequence_directory = fullfile(event.tracker.directory, event.experiment.name, ...
                event.sequence.name);
            
            [~, metadata] = tracker_evaluate(event.tracker, event.sequence, sequence_directory, ...
                'type', event.experiment.type, 'parameters', execution_parameters, 'scan', true);

            context.completed = context.completed && metadata.completed;
            
            % TODO: check if the sequence is not by any chance
            % non-deterministic.
            if isfield(metadata, 'deterministic')
            	context.deterministic = context.deterministic && metadata.deterministic;
            end
    end;

end