function [time] = repeat_trial(tracker, sequence, repetitions, directory)

global track_properties;

mkpath(directory);

total_time = 0;

for i = 1:repetitions

    result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, i));

    if track_properties.cache && exist(result_file, 'file')
        continue;
    end;

    print_indent(1);

    print_text('Repetition %d', i);

    [trajectory, t] = run_trial(tracker, sequence);

    print_indent(-1);

    total_time = total_time + t;
    
    if ~isempty(trajectory)
        csvwrite(result_file, trajectory);
    end;
end;

time = total_time / repetitions;
