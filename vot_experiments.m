function vot_experiments(trackers, sequences, experiments, varargin)

mode = 'execute';

args = varargin;
for j=1:2:length(args)
    switch lower(varargin{j})
        case 'mode', mode = args{j+1};         
        otherwise, error(['unrecognized argument ' args{j}]);
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


