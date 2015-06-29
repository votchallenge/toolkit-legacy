function workspace_evaluate(trackers, sequences, experiments, varargin)
% workspace_evaluate Perform evaluation of a set of trackers
%
% Perform or prepare evaluation of a set of trackers on a set of sequences for 
% a set of experiments.
%
% Input:
% - trackers (cell or structure): Array of tracker structures.
% - sequences (cell or structure): Array of sequence structures.
% - experiments (cell or structure): Array of experiment structures.
% - varargin[Mode] (string, optional): Evaluation mode, at the moment only 'execute' mode is supported.
%


mode = 'execute';

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'mode', mode = varargin{j+1};         
        otherwise, error(['unrecognized argument ' varargin{j}]);
    end
end

switch lower(mode)
    case 'execute' 
        iterator = @execute_iterator;
    otherwise, error(['unrecognized mode ' mode]);
end

iterate(experiments, trackers, sequences, 'iterator', iterator);

print_text('Done.');

end

function context = execute_iterator(event, context)

    switch (event.type)
        case 'experiment_enter'
            
            print_text('Experiment %s', event.experiment.name);

            print_indent(1);       
        case 'experiment_exit'

            print_indent(-1);

        case 'tracker_enter'
            
            print_text('Tracker %s', event.tracker.identifier);

            print_indent(1);  
            
        case 'tracker_exit'

            print_indent(-1);
            
        case 'sequence_enter'
            
            print_text('Sequence %s', event.sequence.name);

            context = struct();
            if isfield(event.experiment, 'parameters')
                context = event.experiment.parameters;
            end;
            
            sequence_directory = fullfile(event.tracker.directory, event.experiment.name, ...
                event.sequence.name);
            
            repeat_trial(event.tracker, event.sequence, sequence_directory, context);
            
    end;

end


