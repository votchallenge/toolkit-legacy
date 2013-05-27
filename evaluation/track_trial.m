function [trajectory, time] = track_trial(tracker, sequence, start)

confirm_recursive_rmdir(0, "local");

% create temporary directory and generate input data
working_directory = track_prepare_trial_data(sequence, start);

output_file = fullfile(working_directory, 'output.txt');

% run the tracker
old_directory = pwd;
try

    print_debug(['INFO: Executing "', tracker.command, '" in "', working_directory, '".']);

    cd(working_directory);

    tic;
    [output, status] = system(tracker.command, 1);
    time = toc;

    if status ~= 0 
        print_debug('WARNING: System command has not exited normally.');
    end;

catch e

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
    trajectory = [];
    time = NaN;
end;

% clean-up temporary directory

rmdir(working_directory, 's');

