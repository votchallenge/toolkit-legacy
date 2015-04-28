function [trajectory, time] = trax_wrapper(tracker, sequence, context)
% TRAX_WRAPPER  A wrapper around the external TraX client that handler running
% the tracker.
%
%   [TRAJECTORY, TIME] = TRAX_WRAPPER(TRACKER, SEQUENCE, CONTEXT)
%              Runs the tracker on a sequence. The resulting trajectory is
%              a composite of all correctly tracked fragments. Where
%              reinitialization occured, the frame is marked using a
%              special notation.
%
%   See also RUN_TRIAL.

trax_executable = get_global_variable('trax_client', '');

if isempty(trax_executable)
    error('TraX support not available');
end;

defaults = struct('directory', tempname, 'skip_labels', {{}}, 'skip_initialize', 1, 'failure_overlap',  -1);

context = struct_merge(context, defaults);

prepare_trial_data(context.directory, sequence, 1, context);

groundtruth_file = fullfile(sequence.directory, sequence.file);

images_file = fullfile(context.directory, 'images.txt');

% Generate an initialization region file

initialization_file = fullfile(context.directory, 'initialization.txt');

initialization = cell(sequence.length, 1);

for index = 1:sequence.length
    
    if ~isempty(intersect(get_labels(sequence, index), context.skip_labels))
        initialization{index} = 0;
    else
        initialization{index} = sequence.initialize(sequence, index, context);
    end; 

end

write_trajectory(initialization_file, initialization);

output_file = fullfile(context.directory, 'output.txt');
timing_file = fullfile(context.directory, 'timing.txt');

arguments = '';

if (context.failure_overlap >= 0)
    arguments = [arguments, sprintf(' -f %.5f', context.failure_overlap)];
end;

if (context.skip_initialize > 0)
    arguments = [arguments, sprintf(' -r %d', context.skip_initialize)];
end;

if ~isempty(tracker.trax_parameters) && iscell(tracker.trax_parameters)
    for i = 1:size(tracker.trax_parameters, 1)
        arguments = [arguments, sprintf(' -p "%s=%s"', ...
            tracker.trax_parameters{i, 1}, num2str(tracker.trax_parameters{i, 2}))]; %#ok<AGROW>
    end
end

% mwrapper requires matlab root on Unix
if ~ispc
    arguments = [arguments, ' -e "MATLAB_ROOT=', matlabroot, '"'];
end

if ispc
command = sprintf('"%s" %s -I "%s" -G "%s" -O "%s" -S "%s" -T "%s" -- %s', trax_executable, ...
    arguments, images_file, groundtruth_file, output_file, ...
    initialization_file, timing_file, tracker.command);
else
command = sprintf('%s %s -I "%s" -G "%s" -O "%s" -S "%s" -T "%s" -- %s', trax_executable, ...
    arguments, images_file, groundtruth_file, output_file, ...
    initialization_file, timing_file, tracker.command);
end

library_path = '';

% in case when we only want to know runtime command for testing
if isfield(context, 'fake') && context.fake
    trajectory = command;
    time = context.directory;
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

    print_debug(['INFO: Executing "', command, '" in "', context.directory, '".']);

    cd(context.directory);

    if is_octave()
        tic;
        [status, output] = system(command, 1);
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
		    [status, output] = system(command);
		    time = toc;
        else
		    tic;
		    [status, output] = system(command, '');
		    time = toc;
		end;
    end;
        
    if status ~= 0 
        print_debug('WARNING: System command has not exited normally.');

        if ~isempty(output)
            print_text('Printing command line output:');
            print_text('-------------------- Begin raw output ------------------------');
            % This prevents printing of backspaces and such
            disp(output(output > 31 | output == 10 | output == 13));
            print_text('--------------------- End raw output -------------------------');
        end;
    
    end;

    trajectory = read_trajectory(output_file);
    
    %time = csvread(timing_file) ./ 1000; % convert to seconds 
	time = time / sequence.length;    

catch e

	% Reassign old library paths if necessary
	if ~isempty(library_path)
		setenv(library_var, library_path);
	end;

    print_debug('ERROR: Exception thrown "%s".', e.message);
end;

cd(old_directory);

if get_global_variable('cleanup', 1)
    % clean-up temporary directory
    recursive_rmdir(context.directory);
end;

end
