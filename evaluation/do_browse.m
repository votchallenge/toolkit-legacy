function do_browse()

script_directory = fileparts(mfilename('fullpath'));
include_dirs = cellfun(@(x) fullfile(script_directory,x), {'', 'utilities', ...
    'tracker', 'sequence', 'measures', 'experiment' , 'tests'}, 'UniformOutput', false); 
if exist('strsplit') ~= 2
	remove_dirs = include_dirs;
else
	% if strsplit is available we can filter out missing paths to avoid warnings
	remove_dirs = include_dirs(ismember(include_dirs, strsplit(path, pathsep)));
end;
if ~isempty(remove_dirs) 
	rmpath(remove_dirs{:});
end;
addpath(include_dirs{:});

initialize_environment;

stack_configuration = str2func(['stack_', experiment_stack]);

stack_configuration();

selected_experiment = [];
selected_sequence = [];

while 1
    
    if isempty(selected_experiment)

        print_text('Choose experiment:');
        print_indent(1);

        for i = 1:length(experiments)
            print_text('%d - "%s"', i, experiments{i});
        end;

        print_text('e - Exit');
        print_indent(-1);


        option = input('Selected sequence: ', 's');

        if (option == 'q' || option == 'e')
            break
        end;
        
        selected_experiment = int32(str2double(option));

        if isempty(selected_experiment) || selected_experiment < 1 || selected_experiment > length(experiments)
            selected_experiment = [];
        end;

        continue;
        
    end;
    
    if isempty(selected_sequence)
        
        selected_sequence = select_sequence(sequences);       
        
        if isempty(selected_sequence)
            selected_experiment = [];
        end;
        
        continue;
        
    end;
    
    experiment_directory = fullfile(tracker.directory, experiments{selected_experiment});
    
    sequence_directory = fullfile(experiment_directory, sequences{selected_sequence}.name);
    
    trajectories = {};
         
    for i = 1:track_properties.repeat
    
        tfile = fullfile(sequence_directory, ...
            sprintf('%s_%03d.txt', sequences{selected_sequence}.name, i));
        
        if exist(tfile, 'file')
            trajectories{end+1} = csvread(tfile);
        end;
    
    end;        
    
    if isempty(trajectories)
        print_text('No results found for sequence');
        selected_sequence = [];
        continue;
    end;
    
    visualize_analysis(sequences{selected_sequence}, trajectories{:});
    
    visualize_sequence(sequences{selected_sequence}, trajectories{:});
    
    selected_sequence = [];
    
end;





