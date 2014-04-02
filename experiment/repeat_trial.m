function repeat_trial(tracker, sequence, directory, varargin)

repetitions = 15;
skip_labels = {};
skip_initialize = 0;
fail_overlap = 0;

args = varargin;
for j=1:2:length(args)
    switch varargin{j}
        case 'repetitions', repetitions = args{j+1};
        case 'skip_labels', skip_labels = args{j+1};
        case 'skip_initialize', skip_initialize = args{j+1};            
        case 'fail_overlap', fail_overlap = args{j+1};            
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

mkpath(directory);

time_file = fullfile(directory, sprintf('%s_time.txt', sequence.name));

if get_global_variable('cache', 0) && exist(time_file, 'file')
    times = csvread(time_file);
else
    times = zeros(sequence.length, 1);
end;

for i = 1:repetitions

    result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, i));

    if get_global_variable('cache', 0) && exist(result_file, 'file')
        continue;
    end;

    if i == 4 && is_deterministic(sequence, 3, directory)
        print_text('Detected a deterministic tracker, skipping remaining trials.');
        break;
    end;

    print_indent(1);

    print_text('Repetition %d', i);

    context = struct('repetition', i, 'repetitions', repetitions);
        
    [trajectory, time] = run_trial(tracker, sequence, context, ...
        'skip_labels', skip_labels, 'fail_overlap', fail_overlap, 'skip_initialize', skip_initialize);
    
    print_indent(-1);

    if numel(time) ~= sequence.length   
        times(:, i) = 1 / mean(time);
    else
        times(:, i) = 1 / time;
    end
    
    if ~isempty(trajectory)
        write_trajectory(result_file, trajectory);
    end;
end;

csvwrite(time_file, times);
