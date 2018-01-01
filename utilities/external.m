function [status, output, elapsed] = external(command, varargin)
% external Utility to run native executables as system commands
%
% This is a wrapper function around the system function that handles
% custom execution directory and linking paths as well as different
% calling conventions between Matlab and Octave versions.
%
% Input:
% - command (string): String of a command to execute
% - varargin[Directory] (string): Set directory for the command
% - varargin[Environment] (cell): List of environment variables to
%   set before execution, each string is of format NAME=VALUE.
% - varargin[LinkPath] (cell): Collection of library paths to add
%   to the call.
%
% Output:
% - status (integer): Status code
% - output (string): Output of the command
% - elapsed (float): Number of seconds used by the command

directory = pwd();
linkpath = {};

args = varargin;
for j=1:2:length(args)
    switch lower(varargin{j})
        case 'directory', directory = args{j+1};
		case 'linkpath', linkpath = args{j+1};
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

if iscell(command)
	command = strjoin(command, ' ');
end;

library_path = '';
output = '';

if ispc
    library_var = 'PATH';
else
    library_var = 'LD_LIBRARY_PATH';
end;

old_directory = pwd;
try

    print_debug(['INFO: Executing "', command, '" in "', directory, '".']);

    cleanup = onCleanup(@() cd(old_directory) ); % Set default path recovery handle

    cd(directory);

    if is_octave()
        tic;
        [status, output] = system(command, 1);
        elapsed = toc;
    else

		% Save library paths
		library_path = getenv(library_var);

        % Make Matlab use system libraries
        if ~isempty(linkpath)
            userpath = linkpath{end};
            if length(linkpath) > 1
                userpath = [sprintf(['%s', pathsep], linkpath{1:end-1}), userpath];
            end;
            setenv(library_var, [userpath, pathsep, library_path]);
        end;

		if verLessThan('matlab', '7.14.0')
		    tic;
		    [status, output] = system(command);
		    elapsed = toc;
        else
		    tic;
		    [status, output] = system(command, '');
		    elapsed = toc;
		end;
    end;

catch e

    print_text('ERROR: Exception thrown "%s".', e.message);

	status = false;

end;

% Reassign old library paths if necessary
if ~isempty(library_path)
	setenv(library_var, library_path);
end;

