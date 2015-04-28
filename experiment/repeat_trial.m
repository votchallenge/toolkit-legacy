function repeat_trial(tracker, sequence, directory, context)

defaults = struct('repetitions', 15, 'skip_labels', {{}}, 'skip_initialize', 0, 'failure_overlap',  -1);

context = struct_merge(context, defaults);

mkpath(directory);

time_file = fullfile(directory, sprintf('%s_time.txt', sequence.name));

if get_global_variable('cache', 0) && exist(time_file, 'file')
    times = csvread(time_file);
else
    times = zeros(sequence.length, context.repetitions);
end;

for i = 1:context.repetitions

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

    context.repetition = i;
            
    [trajectory, time] = tracker.run(tracker, sequence, context);        
    
    print_indent(-1);

    if numel(time) ~= sequence.length   
        times(:, i) = mean(time);
    else
        times(:, i) = time;
    end
    
    if ~isempty(trajectory)
        write_trajectory(result_file, trajectory);
		csvwrite(time_file, times);
    end;
end;

