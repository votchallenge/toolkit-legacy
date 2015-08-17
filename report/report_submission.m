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

measures_labels = {'Overlap', 'Failures', 'Speed'};
context.measures = {@(trajectory, sequence, experiment, tracker) ...
    estimate_accuracy(trajectory, sequence, 'burnin', experiment.parameters.burnin), ...
    @(trajectory, sequence, experiment, tracker) estimate_failures(trajectory, sequence), ...
    @estimate_speed};

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
        
        document.subsection('Experiment %s', experiments{i}.name);
        document.table(context.scores{i}, 'columnLabels', measures_labels, 'rowLabels', sequence_labels, 'title', 'Scores');
        
    end
    
end;

document.write();

end

function context = evaluate_iterator(event, context)

switch (event.type)
    case 'experiment_enter'
        
        print_text('Experiment %s', event.experiment.name);
        
        switch event.experiment.type
            case 'supervised'
                defaults = struct('repetitions', 15, 'skip_labels', {{}}, 'skip_initialize', 0, 'failure_overlap',  -1);
                context.experiment_parameters = struct_merge(event.experiment.parameters, defaults);
                context.scores{event.experiment_index} = nan(numel(context.sequences), numel(context.measures));
            otherwise, error(['unrecognized type ' type]);
        end
        
        print_indent(1);
    case 'experiment_exit'
        
        print_indent(-1);
        
    case 'sequence_enter'
        
        print_text('Sequence %s', event.sequence.name);
        
        sequence_directory = fullfile(event.tracker.directory, event.experiment.name, ...
            event.sequence.name);
        
        switch event.experiment.type
            case 'supervised'
                
                scores = nan(context.experiment_parameters.repetitions, numel(context.measures));
                
                for i = 1:context.experiment_parameters.repetitions
                    
                    result_file = fullfile(sequence_directory, sprintf('%s_%03d.txt', event.sequence.name, i));
                    
                    if ~exist(result_file, 'file')
                        continue;
                    end;
                    
                    if i == 4 && is_deterministic(event.sequence, 3, sequence_directory)
                        print_debug('Detected a deterministic tracker, skipping remaining trials.');
                        break;
                    end;
                    
                    trajectory = read_trajectory(result_file);
                    
                    for m = 1:numel(context.measures)
                        scores(i, m) = context.measures{m}(trajectory, event.sequence, event.experiment, event.tracker);
                    end;
                    
                end;
                
                context.scores{event.experiment_index}(event.sequence_index, :) = nanmean(scores, 1);
                
            otherwise, error(['unrecognized type ' type]);
        end
        
end;

end

function speed = estimate_speed(trajectory, sequence, experiment, tracker)

directory = fullfile(tracker.directory, experiment.name, ...
    sequence.name);

times_file = fullfile(directory, sprintf('%s_time.txt', sequence.name));

times = csvread(times_file);

speed = 1 / nanmean(times(:), 1);

end

