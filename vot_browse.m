function vot_browse(trackers, sequences, experiments)

selected_tracker = [];
selected_experiment = [];
selected_sequence = [];

while 1
    
    if isempty(selected_tracker)

        if length(trackers) == 1
            selected_tracker = 1;
            
            continue;
        else
        
            print_text('Choose tracker:');
            print_indent(1);

            for i = 1:length(trackers)
                print_text('%d - "%s"', i, trackers{i}.identifier);
            end;

            print_text('e - Exit');
            print_indent(-1);


            option = input('Selected tracker: ', 's');

            if (option == 'q' || option == 'e')
                break
            end;

            selected_tracker = int32(str2double(option));

            if isempty(selected_tracker) || selected_tracker < 1 || selected_tracker > length(trackers)
                selected_tracker = [];
            end;

            continue;
        
        end;
    end;
    
    if isempty(selected_experiment)

        print_text('Choose experiment:');
        print_indent(1);

        for i = 1:length(experiments)
            print_text('%d - "%s"', i, experiments{i}.name);
        end;

        print_text('e - Exit');
        print_indent(-1);


        option = input('Select experiment: ', 's');

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
    
    tracker = trackers{selected_tracker};
    
    experiment_directory = fullfile(tracker.directory, experiments{selected_experiment}.name);
    
    sequence_directory = fullfile(experiment_directory, sequences{selected_sequence}.name);
    
    trajectories = {};
         
    for i = 1:experiments{selected_experiment}.parameters.repetitions;
    
        tfile = fullfile(sequence_directory, ...
            sprintf('%s_%03d.txt', sequences{selected_sequence}.name, i));
        
        if exist(tfile, 'file')
            trajectories{end+1} = read_trajectory(tfile); %#ok<AGROW>
        end;
    
    end;        
    
    if isempty(trajectories)
        print_text('No results found for sequence');
        selected_sequence = [];
        continue;
    end;

    visualize_sequence(sequences{selected_sequence}, trajectories{:});
    
    selected_sequence = [];
    
end;





