function data = tracker_run(tracker, callback, data)
% tracker_run General purpose function to run a tracker and communicate
% with it
%
% This function runs the traxclient executable in a query mode to test
% if a tracker supports the TraX protocol. The results are chached
% in the workspace cache directory.
%
% Input:
% - tracker (struct): Tracker structure
% - callback (function): A function handle triggered for every TraX event
% - data (any): Custom data for the callback
%
% Output:
% - data (any): Resulting data object returned by the last call to
% callback.

% Check if the result of the test is already cached

directory = tempname();

mkpath(directory);

debug_console = get_global_variable('trax_debug_console', false);
debug = get_global_variable('trax_debug', false);
cleanup = get_global_variable('log_autocleanup', true);

% Specify timeout period
if isfield(tracker.parameters, 'timeout')
    timeout = tracker.parameters.timeout;
else
    timeout = get_global_variable('trax_timeout', 30);
end;

% Hint to tracker that it should use trax
environment.TRAX = '1';

connection = 'standard';

% If we are running Matlab tracker on Windows, we have to use TCP/IP
% sockets
if ispc && strcmpi(tracker.interpreter, 'matlab')
    connection = 'socket';
end

if ispc
    library_var = 'PATH';
else
    library_var = 'LD_LIBRARY_PATH';
end;

if ~isempty(tracker.linkpath)
    userpath = strjoin(tracker.linkpath, pathsep);
    environment.(library_var) = [userpath, pathsep, getenv('PATH')];
else
    environment.(library_var) = getenv('PATH');
end;

log_directory = fullfile(get_global_variable('directory'), 'logs', tracker.identifier);
mkpath(log_directory);

mexargs = {'Debug', debug};

timestamp = datestr(now, 30);

if ~debug_console
    log_file = fullfile(log_directory, [timestamp, '.log']);
else
    log_file = '#'; % Print to command window.
end;

mexargs = [mexargs, 'Log', log_file];

failure = [];

try
    data = traxclient(tracker.command, callback, ...
        'Directory', directory, 'Timeout', timeout, ...
        'Environment', environment, 'Connection', connection, ...
        'Data', data, mexargs{:});
catch e
    print_text('Tracker execution interrupted: %s', e.message);
    failure = e;
end;

if ~isempty(failure)
    if exist(fullfile(directory, 'runtime.log'), 'file')
        copyfile(fullfile(directory, 'runtime.log'), fullfile(log_directory, [timestamp, '_runtime.log']));
    end
end

if ispc()
    % On Windows working directory frequently remains locked for some short
    % time so we have to try it several times.
    for i = 1:4
        if delpath(directory, 'Empty', ~isempty(failure))
            break;
        end
        pause(0.5);
    end;
else
    delpath(directory, 'Empty', ~isempty(failure));
end;

if isempty(failure)
    if cleanup && ~debug_console
       delpath(log_file);
    end
else
	rethrow(failure);
end

end


