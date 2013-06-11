function [trajectory, time] = run_tracker(tracker, sequence, start)
% RUN_TRACKER  Generates input data for the tracker, runs the tracker and
%              validates results.
%
%   [TRAJECTORY, TIME] = RUN_TRACKER(TRACKER, SEQUENCE, START)
%              Runs the tracker on a sequence that with a specified offset.
%
%   See also RUN_TRIAL, SYSTEM.

% create temporary directory and generate input data
working_directory = prepare_trial_data(sequence, start);

output_file = fullfile(working_directory, 'output.txt');

library_path = '';

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

		% Save library paths
		library_path = getenv('LD_LIBRARY_PATH');

		% Make Matlab use system libraries
		setenv('LD_LIBRARY_PATH', getenv('PATH'));

		if verLessThan('matlab', '7.14.0')
		    tic;
		    [status, output] = system(tracker.command);
		    time = toc;
		else
		    tic;
		    [status, output] = system(tracker.command, '');
		    time = toc;
		end;
    end;
        
    if status ~= 0 
        print_debug('WARNING: System command has not exited normally.');
    end;

catch e

	% Reassign old library paths if necessary
	if ~isempty(library_path)
		setenv('LD_LIBRARY_PATH', library_path);
	end;

    print_debug('ERROR: Exception thrown "%s".', e.message);
end;

cd(old_directory);

% validate and process results
trajectory = load_trajectory(output_file);

n_frames = size(trajectory, 1);

time = time / (sequence.length-start);

if (n_frames ~= (sequence.length-start) + 1)
    print_debug('WARNING: Tracker did not produce a trajectory file.');
    trajectory = [];
    time = NaN;
end;

% clean-up temporary directory
recursive_rmdir(working_directory);

