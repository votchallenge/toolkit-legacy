
error('Tracker not configured! Please edit the tracker_{{tracker}}.m file.'); % Remove this line after proper configuration

% The human readable label for the tracker, used to identify the tracker in reports
% If not set, it will be set to the same value as the identifier.
% It does not have to be unique, but it is best that it is.
tracker_label = [];

% Now you have to set up the system command to be run.
% For classical executables this is usually just a full path to the executable plus
% optional arguments:

tracker_command = '<TODO: set a tracker executable command>';

% tracker_interpreter = []; % Set the interpreter used here as a lower case string. E.g. if you are using Matlab, write 'matlab'. (optional)

% tracker_linkpath = {}; % A cell array of custom library directories used by the tracker executable (optional)

% tracker_trax = false; % Uncomment to manually disable TraX protocol testing
