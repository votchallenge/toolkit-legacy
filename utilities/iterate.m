function context = iterate(experiments, trackers, sequences, varargin)
% Performs iteration over a given experiment, tracker and sequence triplets

iterator = @default_iterator;
context = [];

args = varargin;
for j=1:2:length(args)
    switch lower(varargin{j})
        case 'iterator', iterator = args{j+1};
        case 'context', context = args{j+1};   
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

if ~iscell(experiments)
    experiments = {experiments};
end;

if ~iscell(trackers)
    trackers = {trackers};
end;

if ~iscell(sequences)
    sequences = {sequences};
end;

context = iterator(struct('type', 'enter'), context);

for e = 1:numel(experiments)

    converter = experiments{e}.converter;
    
    event = struct('type', 'experiment_enter', 'experiment', experiments{e}, 'experiment_index', e);
    
    context = iterator(event, context);
    
    experiment_sequences = convert_sequences(sequences, converter);
    
    for t = 1:numel(trackers);
    
        event = struct('type', 'tracker_enter', 'experiment', experiments{e}, 'experiment_index', e, ...
            'tracker', trackers{t}, 'tracker_index', t);
        
        context = iterator(event, context);
        
        for s = 1:numel(experiment_sequences)

            event = struct('type', 'sequence_enter', 'experiment', experiments{e}, 'experiment_index', e, ...
                'tracker', trackers{t}, 'tracker_index', t, 'sequence', experiment_sequences{s}, ...
                'sequence_index', s);
            
            context = iterator(event, context);
            
        end;
        
        event = struct('type', 'tracker_exit', 'experiment', experiments{e}, 'experiment_index', e, ...
            'tracker', trackers{t}, 'tracker_index', t);        
        
        context = iterator(event, context);
        
    end;
    
    event = struct('type', 'experiment_exit', 'experiment', experiments{e}, 'experiment_index', e);
    
    context = iterator(event, context);
    
end;

context = iterator(struct('type', 'exit'), context);

end

function context = default_iterator(event, context)

    switch (event.type)
        case 'experiment_enter'
            
            print_debug('Experiment %s', event.experiment.name);

            print_indent(1);       
        case 'experiment_exit'

            print_indent(-1);

        case 'tracker_enter'
            
            print_debug('Tracker %s', event.tracker.identifier);

            print_indent(1);  
            
        case 'tracker_exit'

            print_indent(-1);
            
        case 'sequence_enter'
            
            print_debug('Sequence %s', event.sequence.name);
   
    end;

end

