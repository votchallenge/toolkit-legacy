function [trajectory, time] = track_trial(tracker, sequence, start)

% create temporary directory and generate input data
working_directory = track_prepare_trial_data(sequence, start);

output_file = fullfile(working_directory, 'output.txt');

% run the tracker
old_directory = pwd;
try

    print_debug(['INFO: Executing "', tracker.command, '" in "', working_directory, '".']);

    cd(working_directory);

    if is_octave()
        tic;
        [status, output] = system(tracker.command, 1);
        time = toc;
    else
        tic;
        [status, output] = system(tracker.command, '');
        time = toc;
    end;
        
    if status ~= 0 
        print_debug('WARNING: System command has not exited normally.');
    end;

catch e
    print_debug('ERROR: Exception thrown "%s".', e.message);
end;

cd(old_directory);

% validate and process results

if exist(output_file, 'file')
    trajectory = double(csvread(output_file));

    [n_frames, n_values] = size(trajectory);

    if n_values ~= 4
        trajectory = [];
    end;

    if (n_frames ~= (sequence.length-start) + 1)
        trajectory = [];
        time = NaN;
    end;

else
    print_debug('WARNING: Tracker did not produce a trajectory file.');
    trajectory = [];
    time = NaN;
end;

% clean-up temporary directory

recursive_rmdir(working_directory);

