function [time] = repeat_trial(tracker, sequence, repetitions, directory, varargin)

global track_properties;

skip_initialize = {};

args = varargin;
for j=1:2:length(args)
    switch varargin{j}
        case 'skip_initialize', skip_initialize = args{j+1};
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

mkpath(directory);

total_time = 0;

time_file = fullfile(directory, sprintf('%s_time.txt', sequence.name));

if track_properties.cache && exist(time_file, 'file')
    times = csvread(time_file);
else
    times = zeros(1, repetitions);
end;

for i = 1:repetitions

    result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, i));

    if track_properties.cache && exist(result_file, 'file')
        continue;
    end;

    if i == 4 && is_deterministic(sequence, 3, directory)
        print_text('Detected a deterministic tracker, skipping remaining trials.');
        break;
    end;

    print_indent(1);

    print_text('Repetition %d', i);

    context = struct('repetition', i, 'repetitions', repetitions);
    
    [trajectory, t] = run_trial(tracker, sequence, context, 'skip_initialize', skip_initialize);

    print_indent(-1);

    total_time = total_time + t;
    
    times(i) = 1 / t;
    
    if ~isempty(trajectory)
        csvwrite(result_file, trajectory);
    end;
end;

csvwrite(time_file, times);

time = total_time / repetitions;
