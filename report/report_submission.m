function [document] = report_submission(context, trackers, sequences, experiments, varargin)
% report_submission Basic performance scores for given trackers
%
% This function generates basic report with some performance scores that
% can be included in the supporting document when submitting the tracker to
% the challenge.
%
% Input:
% - context (structure): Report context structure.
% - trackers (struct): An array of tracker structures.
% - experiments (cell): An array of experiment structures.
% - sequences (cell): An array of sequence structures.
%
% Output:
% - document (structure): Resulting document structure.

if ~iscell(trackers)
    trackers = {trackers};
end;

document = create_document(context, 'submission', 'title', 'Submission report');


for t = 1:numel(trackers)
    tracker = trackers{t};
    
    document.section('Tracker %s', tracker.label);
    
    context.sequences = sequences;
    context.scores = cell(numel(experiments), 1);
    
    context = iterate(experiments, tracker, sequences, 'iterator', @evaluate_iterator, 'context', context);

    sequence_labels = cellfun(@(x) x.name, sequences, 'UniformOutput', 0)';
    
    for i = 1:numel(experiments)
        
        row_labels = [sequence_labels; 'Average'];
        
        data = context.scores{i}.data;
        data(end+1, :) = sum(bsxfun(@times, context.scores{i}.data, context.scores{i}.sequence_lengths')) ./ sum(context.scores{i}.sequence_lengths); %#ok<AGROW>
        
        document.subsection('Experiment %s', experiments{i}.name);
        document.table(data, 'columnLabels', context.scores{i}.labels, 'rowLabels', row_labels, 'title', 'Scores');
        
    end
    
end;

document.write();

end

function context = evaluate_iterator(event, context)

switch (event.type)
    case 'experiment_enter'
        
        print_text('Experiment %s', event.experiment.name);
        
        context.experiment_sequences = convert_sequences(context.sequences, event.experiment.converter);
        
        switch event.experiment.type
            case {'supervised'}
                defaults = struct('repetitions', 15, 'skip_labels', {{}}, 'skip_initialize', 0, 'failure_overlap',  -1);
                context.experiment_parameters = struct_merge(event.experiment.parameters, defaults);
                context.scores{event.experiment_index}.labels = {'Overlap', 'Failures', 'Speed'};
                context.scores{event.experiment_index}.measures = {@(trajectory, sequence, experiment, tracker) ...
                    estimate_accuracy(trajectory, sequence, 'burnin', experiment.parameters.burnin), ...
                    @(trajectory, sequence, experiment, tracker) estimate_failures(trajectory, sequence), ...
                    @estimate_speed};
                context.scores{event.experiment_index}.data = nan(numel(context.sequences), 3);
            case {'chunked', 'unsupervised'}
                defaults = struct('repetitions', 15, 'skip_labels', {{}}, 'skip_initialize', 0, 'failure_overlap',  -1);
                context.experiment_parameters = struct_merge(event.experiment.parameters, defaults);
                context.scores{event.experiment_index}.labels = {'Overlap', 'Speed'};
                context.scores{event.experiment_index}.measures = {@(trajectory, sequence, experiment, tracker) ...
                    estimate_accuracy(trajectory, sequence, 'burnin', experiment.parameters.burnin, 'IgnoreUnknown', false), ...
                    @estimate_speed};
                context.scores{event.experiment_index}.data = nan(numel(context.sequences), 2);
            otherwise, error(['unrecognized type ' type]);
        end
        
        context.scores{event.experiment_index}.sequence_lengths = cellfun(@(x) x.length, context.experiment_sequences, 'UniformOutput', true);
        
        print_indent(1);
    case 'experiment_exit'
        
        print_indent(-1);
        
    case 'sequence_enter'
        
        sequence = context.experiment_sequences{event.sequence_index};
        
        print_text('Sequence %s', sequence.name);
        
        sequence_directory = fullfile(event.tracker.directory, event.experiment.name, ...
            sequence.name);
        
        switch event.experiment.type
            case {'supervised', 'unsupervised', 'chunked'}
                
                scores = nan(context.experiment_parameters.repetitions, numel(context.scores{event.experiment_index}.measures));
                
                for i = 1:context.experiment_parameters.repetitions
                    
                    result_file = fullfile(sequence_directory, sprintf('%s_%03d.txt', event.sequence.name, i));
                    
                    if ~exist(result_file, 'file')
                        continue;
                    end;
                    
                    if i == 4 && is_deterministic(sequence, 3, sequence_directory)
                        print_debug('Detected a deterministic tracker, skipping remaining trials.');
                        break;
                    end;
                    
                    trajectory = read_trajectory(result_file);
                    
                    for m = 1:numel(context.scores{event.experiment_index}.measures)
                        scores(i, m) = context.scores{event.experiment_index}.measures{m}(trajectory, sequence, event.experiment, event.tracker);
                    end;
                    
                end;
                
                context.scores{event.experiment_index}.data(event.sequence_index, :) = nanmean(scores, 1);
                
            otherwise, error(['unrecognized type ' type]);
        end
        
end;

end

function speed = estimate_speed(trajectory, sequence, experiment, tracker)

directory = fullfile(tracker.directory, experiment.name, ...
    sequence.name);

times_file = fullfile(directory, sprintf('%s_time.txt', sequence.name));

times = csvread(times_file);

times = times(:, ~all(times == 0 | isnan(times), 1));

speed = 1 / nanmean(times(:), 1);

end

