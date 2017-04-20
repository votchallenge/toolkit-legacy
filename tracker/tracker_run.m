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
timeout = get_global_variable('trax_timeout', 30);

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

if ~debug_console
    log_file = fullfile(log_directory, [datestr(now, 30), '.log']);
    mexargs = [mexargs, 'Log', log_file];
end;

try
    data = traxclient(tracker.command, callback, ...
        'Directory', directory, 'Timeout', timeout, ...
        'Environment', environment, 'Connection', connection, ...
        'Data', data, mexargs{:});
    success = true;
catch e
    print_text('Tracker execution interrupted: %s.', e.message)
    print_text('Writing log output to a file %s, working directory of the tracker was %s.', log_file, directory);
    success = false;
end;

delpath(directory, 'Empty', ~success);

if success
    if cleanup && ~debug_console
       delpath(log_file); 
    end
end

end


