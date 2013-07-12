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

global current_sequence;
global trajectory;

if ~exist('trajectory', 'var')
	trajectory = [];
end;

if ~exist('current_sequence', 'var')
	current_sequence = 1;
end;

performance = struct('frames', 0, 'time', 0);

print_text('');
print_text('***************************************************************************');
print_text('');
print_text('Welcome to the VOT sandbox!');
print_text('This process will help you prepare your tracker for the evaluation.');
print_text('When beginning with the integration it is recommended to follow the steps ');
print_text('a, b, c to verify the execution and the output data.');
print_text('');
print_text('***************************************************************************');
print_text('');

i = 0;
while 1
    print_text('Choose action:');
    print_indent(1);

    print_text('a - Generate a directory with input data for manual test');
    print_text('b - Run tracker once within the evaluation');
    if ~isempty(trajectory)
        print_text('c - Visually compare results with the groundtruth');
    end;
    if track_properties.debug
        print_text('d - Disable debug output');
    else
        print_text('d - Enable debug output');
    end;
    if performance.frames > 0
        print_text('t - Estimate required time for a single experiment on the given sequence set');
    end;
    print_text('e - Exit');
    print_indent(-1);

    option = input('Choose action: ', 's');

    switch option
    case 'a'
        current_sequence = select_sequence(sequences);       
        
        if ~isempty(current_sequence)
            
            directory = prepare_trial_data(sequences{current_sequence}, 1, struct('repetition', 1, 'repetitions', 1));
            
            print_text('Input data generated in directory "%s"', directory);
            print_text('Open the directory in a terminal and manually execute the tracker command.');
            print_text('The current command as defined in the environment is: %s', tracker.command);
            print_text('Once the tracker is working as expected, delete the directory.');
        end;
    case 'b'
        current_sequence = select_sequence(sequences);       
        
        if ~isempty(current_sequence)

            print_text('Sequence "%s"', sequences{current_sequence}.name);
            [trajectory, time] = tracker.run(tracker, sequences{current_sequence}, 1, struct('repetition', 1, 'repetitions', 1));

            performance.time = performance.time + time * sequences{current_sequence}.length;

            performance.frames = performance.frames + sequences{current_sequence}.length;
        end;        
    case 'c'
        if ~isempty(trajectory) && current_sequence > 0 && current_sequence <= length(sequences)
            visualize_sequence(sequences{current_sequence}, trajectory);
        end;
    case 't'
        if performance.frames > 0
            
            fps = performance.frames / performance.time;
            
            estimate = estimate_completion_time(sequences, 'fps', fps);
            
            print_text('Based on the current estimate (fps = %.2f), the completion time for %d sequences is %s', fps, length(sequences), format_interval(estimate));
            
        end;   
	case 'd'
		track_properties.debug = ~track_properties.debug;
    case 'e'
        break;
    case 'q'
        break;

    end;
    
end;





