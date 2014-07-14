function [trajectory, time] = trax_wrapper(tracker, sequence, context, varargin)
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

skip_labels = {};

skip_initialize = 1;

fail_overlap = -1;

args = varargin;
for j=1:2:length(args)
    switch varargin{j}
        case 'skip_labels', skip_labels = args{j+1};
        case 'skip_initialize', skip_initialize = max(1, args{j+1}); 
        case 'fail_overlap', fail_overlap = args{j+1};
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

working_directory = prepare_trial_data(sequence, 1, context);

groundtruth_file = fullfile(sequence.directory, sequence.file);

images_file = fullfile(working_directory, 'images.txt');

% Generate an initialization region file

initialization_file = fullfile(working_directory, 'initialization.txt');

initialization = cell(sequence.length, 1);

for index = 1:sequence.length
    
    if ~isempty(intersect(get_labels(sequence, index), skip_labels))
        initialization{index} = 0;
    else
        initialization{index} = sequence.initialize(sequence, index, context);
    end; 

end

write_trajectory(initialization_file, initialization);

output_file = fullfile(working_directory, 'output.txt');
timing_file = fullfile(working_directory, 'timing.txt');

arguments = '';

if (fail_overlap >= 0)
    arguments = [arguments, sprintf(' -f %.5f', fail_overlap)];
end;

if (skip_initialize > 0)
    arguments = [arguments, sprintf(' -r %d', skip_initialize)];
end;

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

    print_debug(['INFO: Executing "', command, '" in "', working_directory, '".']);

    cd(working_directory);

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
    recursive_rmdir(working_directory);
end;

end
