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
% - varargin[Variables] (struct, optional): Additional global variables to
% be merged with (override) the existing ones.
%

mode = 'execute';
variables = [];

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'mode', mode = varargin{j+1};
        case 'variables', variables = varargin{j+1};
        otherwise, error(['unrecognized argument ' varargin{j}]);
    end
end

if isstruct(variables)
    print_debug('Setting additional global variables');
    set_global_variable(variables); 
end

switch lower(mode)
    case 'execute' 
        iterator = @execute_iterator;
        context = [];
    case 'makefile'
        if ~isunix
            error('Exporting to Makefile only supported on Unix-like systems.');
        end;
        iterator = @makefile_iterator;
        context = struct('makefilename', 'Makefile');
    otherwise, error(['unrecognized mode ' mode]);
end

iterate(experiments, trackers, sequences, 'iterator', iterator, 'context', context);

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

            if ~event.tracker.trax
                print_text('');
                print_text('***************************************************************************');
                print_text('');
                print_text('                       * DEPRECATION WARNING * ');
                print_text('');
                print_text('You are using an outdated mechanism for communication between the tracker');
                print_text('and the VOT toolkit. Starting with the next version of the toolkit the ');
                print_text('support for this mechanism will be removed completely. We recommend that');
                print_text('you switch to TraX protocol before that time to avoid any problems and to');
                print_text('help us with testing of the protocol.');
                print_text('');
                print_text('***************************************************************************');
                print_text('');
            end;

            print_indent(1);  
            
        case 'tracker_exit'

            print_indent(-1);
            
        case 'sequence_enter'
            
            print_text('Sequence %s', event.sequence.name);

            execution_parameters = struct();
            if isfield(event.experiment, 'parameters')
                execution_parameters = event.experiment.parameters;
            end;
            
            sequence_directory = fullfile(event.tracker.directory, event.experiment.name, ...
                event.sequence.name);

            tracker_evaluate(event.tracker, event.sequence, sequence_directory, ...
                'type', event.experiment.type, 'parameters', execution_parameters);

    end;

end

function context = makefile_iterator(event, context)

    switch (event.type)
        case 'enter'
            
            context.file = fopen(context.makefilename, 'w');

        case 'exit'
            
            fclose(context.file);

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

            execution_parameters = struct();
            if isfield(event.experiment, 'parameters')
                execution_parameters = event.experiment.parameters;
            end;
            
            sequence_directory = fullfile(event.tracker.directory, event.experiment.name, ...
                event.sequence.name);

            tracker_evaluate(event.tracker, event.sequence, sequence_directory, ...
                'type', event.experiment.type, 'parameters', execution_parameters);

    end;

end
