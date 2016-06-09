function [trajectory, time] = system_wrapper(tracker, sequence, context)
% system_wrapper Legacy approach to experiment execution
%
% A wrapper around external system command that handles reinitialization when the tracker fails.
% This function supports the legacy approach to experiment execution.
%
% Input:
% - tracker: Tracker structure.
% - sequence: Sequence structure.
% - context: Execution context structure. This structure contains parameters of the execution.
%
% Output:
% - trajectory: A trajectory In case of fake execution mode the function returns the execution command string.
% - time: Elapsed time in seconds. In case of fake execution mode the function returns the working directory.

defaults = struct('directory', tempname, 'skip_labels', {{}}, 'skip_initialize', 1, 'failure_overlap',  -1);

bind_within = get_global_variable('bounded_overlap', true);

context = struct_merge(context, defaults);

start = 1;

total_time = 0;
total_frames = 0;

trajectory = cell(sequence.length, 1);

trajectory(:) = {0};

if bind_within
    bounds = [sequence.width, sequence.height] - 1;
else
    bounds = [];
end;

while start < sequence.length

    [Tr, Tm] = run_once(context.directory, tracker, sequence, start, context);

    % in case when we only want to know runtime command for testing
    if isfield(context, 'fake') && context.fake
        trajectory = Tr;
        time = Tm;
        return;
    end
    
    if isempty(Tr)
        trajectory = [];
        time = NaN;
        return;
    end;

    total_time = total_time + Tm * size(Tr, 1);
    total_frames = total_frames + size(Tr, 1);

    overlap = calculate_overlap(Tr, get_region(sequence, start:sequence.length), bounds);

    failures = find(overlap' <= context.failure_overlap | ~isfinite(overlap'));
    failures = failures(failures > 1);

    trajectory(start) = {1};
        
    if ~isempty(failures)

        first_failure = failures(1) + start - 1;
        
        trajectory(start + 1:min(first_failure, size(Tr, 1) + start - 1)) = ...
            Tr(2:min(first_failure - start + 1, size(Tr, 1)));

        trajectory(first_failure) = {2};
        
        if context.skip_initialize > 0

            start = first_failure + context.skip_initialize;

            print_debug('INFO: Detected failure at frame %d.', first_failure);

            if ~isempty(context.skip_labels)
                for i = start:sequence.length
                    if isempty(intersect(get_labels(sequence, i), context.skip_labels))
                        start = i;
                        break;
                    end;                
                end;
            end;

            print_debug('INFO: Reinitializing at frame %d.', start);
        
        else
            
            break;

        end;
    else
        
        if size(Tr, 1) > 1
            trajectory(start + 1:min(sequence.length, size(Tr, 1) + start - 1)) = ...
                Tr(2:min(sequence.length - start + 1, size(Tr, 1)));
        end;
        
        start = sequence.length;
    end;

    drawnow;
    
end;

time = total_time / total_frames;

end

function [trajectory, time] = run_once(working_directory, tracker, sequence, start, context)
% Generates input data for the tracker, runs the tracker and validates results.
%
%   [TRAJECTORY, TIME] = RUN_TRACKER(TRACKER, SEQUENCE, START, CONTEXT)
%              Runs the tracker on a sequence that with a specified offset.
%

% create temporary directory and generate input data

if isempty(tracker.command)
    error('Unable to execute tracker %s. No command given.', tracker.identifier);
end;

prepare_trial_data(working_directory, sequence, start, context);

output_file = fullfile(working_directory, 'output.txt');

library_path = '';

output = [];

% in case when we only want to know runtime command for testing
if isfield(context, 'fake') && context.fake
    trajectory = tracker.command;
    time = working_directory;
    return;
end

if ispc
    library_var = 'PATH';
else
    library_var = 'LD_LIBRARY_PATH';
end;

% run the tracker
old_directory = pwd;
try

    print_debug(['INFO: Executing "', tracker.command, '" in "', working_directory, '".']);

    cleanup = onCleanup(@() cd(old_directory) ); % Set default path recovery handle
    
    cd(working_directory);

    if is_octave()
        tic;
        [status, output] = system(tracker.command, 1);
        time = toc;
    else

		% Save library paths
		library_path = getenv(library_var);

        % Make Matlab use system libraries
        if ~isempty(tracker.linkpath)
            userpath = tracker.linkpath{end};
            if length(tracker.linkpath) > 1
                userpath = [sprintf(['%s', pathsep], tracker.linkpath{1:end-1}), userpath];
            end;
            setenv(library_var, [userpath, pathsep, getenv('PATH')]);
        else
		    setenv(library_var, getenv('PATH'));
        end;

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
		setenv(library_var, library_path);
	end;

    print_text('ERROR: Exception thrown "%s".', e.message);
end;

cd(old_directory);
rehash;

% validate and process results
if exist(output_file, 'file')
    trajectory = read_trajectory(output_file);
else
    trajectory = {};
end;

n_frames = size(trajectory, 1);

time = time / (sequence.length-start);

if (n_frames ~= (sequence.length-start) + 1)
    print_debug('WARNING: Tracker did not produce a valid trajectory file.');
    
    if ~isempty(output)
        print_debug('Writing tracker output to a log file.');
        fid = fopen(fullfile(context.directory, 'runtime.log'), 'w');            
        fprintf(fid, '%s', output);
        fclose(fid);
    end;

    logdir = generate_crash_report(tracker, context);
    
    if isempty(trajectory)
        error('No result produced by tracker. Report written to "%s"', logdir);
    else
        error('The number of frames is not the same as in groundtruth. Stopping.');
    end;
end;

if get_global_variable('cleanup', 1)
    try
        % clean-up temporary directory
        delpath(working_directory);
    catch
        print_debug('WARNING: unable to remove directory %s', working_directory);
    end
end;

end

