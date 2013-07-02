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

i = 0;
while 1
    print_text('Choose action:');
    print_indent(1);

    for i = 1:length(sequences)
        print_text('%d - Use sequence "%s"', i, sequences{i}.name);
    end;
    if ~isempty(trajectory)
        print_text('c - Visually compare results with the groundtruth');
    end;
    if performance.frames > 0
        print_text('t - Display required estimate');
    end;
    if track_properties.debug
        print_text('d - Disable debug output');
    else
        print_text('d - Enable debug output');
    end;
    print_text('e - Exit');
    print_indent(-1);

    option = input('Choose action: ', 's');

    switch option
    case 'c'
        if ~isempty(trajectory) && current_sequence > 0 && current_sequence <= length(sequences)
            visualize_sequence(sequences{current_sequence}, trajectory);
        end;
    case 't'
        if performance.frames > 0
            
            estimate = estimate_completion_time(sequences, 'fps', performance.time / performance.frames);
            
            print_test('Based on current estimate, the completion time for %d sequences is %s', length(sequences), format_interval(estimate));
            
        end;   
	case 'd'
		track_properties.debug = ~track_properties.debug;
    case 'e'
        break;
    case 'q'
        break;

    end;

    current_sequence = int32(str2double(option));

    if isempty(current_sequence) || current_sequence < 1 || current_sequence > length(sequences)
        continue;
    end;

    print_text('Sequence "%s"', sequences{current_sequence}.name);
    [trajectory, time] = tracker.run(tracker, sequences{current_sequence}, 1, struct('repetition', 1, 'repetitions', 1));

    performance.time = performance.time + time * sequences{current_sequence}.length;
    
    performance.frames = performance.frames + sequences{current_sequence}.length;
    
end;





