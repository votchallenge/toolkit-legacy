function workspace_visualize(trackers, sequences, experiments, varargin)
% workspace_visualize Create a directory with image visualization of tracker performance 
%
% This function performs a visual report of trackers performance. 
% The created directory with images contains a visual performance of trackers
% for each sequence.
%
% Input:
% - tracker (structure): A valid tracker structure.
% - sequences (cell): Array of sequence structures.
% - experiments (cell): Array of experiment structures.
% - varargin[Directory] (string): Directory where the images should be stored.
%
% Output:
% - [Directory] with images visualizing trackers performance
%

    directory = fullfile(get_global_variable('directory'), 'visualization');

    if nargin > 4 && strcmpi(varargin{j}, 'directory')
        directory = varargin{j+1}; 
    end
    
    if ~iscell(trackers)
        trackers = {trackers};
    end;
    
    print_indent(0);
    
    print_text('Prepraring visualization');    
    
    mkpath(directory);

    print_indent(1);

    context.completed = true;
    
    context = iterate(experiments, trackers, sequences, 'iterator', @gather_iterator, 'context', context);

    if ~context.completed
        print_text('Error: Results are not complete, can not visualize results, aborting.');
        return;
    end;

    % additional context variables for report_visualization
    context.directory = directory;
    
    report_visualization(context, trackers, sequences, experiments);

    print_indent(-1);
    print_text('Done.');

end

function context = gather_iterator(event, context)

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
            
            [~, completed] = tracker_evaluate(event.tracker, event.sequence, sequence_directory, ...
                'type', event.experiment.type, 'parameters', execution_parameters, 'scan', true);

            context.completed = context.completed && completed;
    end;

end

