script_directory = fileparts(mfilename('fullpath'));
include_dirs = cellfun(@(x) fullfile(script_directory,x), {'', 'utilities', 'tracker', 'sequence', 'measures', 'experiment'}, 'UniformOutput', false); 
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

global trajectory;

if ~exist('trajectory', 'var')
	trajectory = [];
end;

i = 0;
while 1
    print_text('Choose action:');
    print_indent(1);

    for i = 1:length(sequences)
        print_text('%d - Use sequence "%s"', i, sequences{i}.name);
    end;
    if ~isempty(trajectory)
        print_text('c - Visually compare results with groundtruth');
    end;
	print_text('d - Toggle debug output');
    print_text('e - Exit');
    print_indent(-1);

    option = input('Choose action: ', 's');

    switch option
    case 'c'
        if ~isempty(trajectory) && sq > 0 && sq <= length(sequences)
            visualize_sequence(sequences{sq}, trajectory);
        end;
        continue;
	case 'd'
		track_properties.debug = ~track_properties.debug;
    case 'e'
        break;
    default

    end;

    sq = int32(str2num(option));

    if isempty(sq) || sq < 1 || sq > length(sequences)
        continue;
    end;

    print_text('Sequence "%s"', sequences{sq}.name);
    [trajectory, time] = run_tracker(tracker, sequences{sq}, 1);

end;





