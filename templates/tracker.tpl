
error('Tracker not configured!'); % Remove this line after proper configuration

% The human readable label for the tracker, used to identify the tracker in reports
% If not set, it will be set to the same value as the identifier.
% It does not have to be unique, but it is best that it is.
tracker_label = [];

% Now you have to set up the system command to be run.
% For classical executables this is usually just a full path to the executable plus
% some optional arguments:
%
% tracker_command = fullfile(pwd, '..', 'examples', 'c', 'static');
%
% For MATLAB implementations there are several options. If you are using the TraX protocol
% and you are using MEX function (Linux and OSX systems only) then you have to run Matlab
% in GUI-less mode and run the script at startup (for more details check the Integration
% instructions). You can use the same form of command that can also be used in case of 
% the old integration approach:
% 
% tracker_command = '<TODO: path to Matlab installation>/bin/matlab -nodesktop -nosplash -r wrapper' % Linux and OSX version  (old approach and TraX using MEX)
% tracker_command = '<TODO: path to Matlab installation>\bin\matlab.exe -wait -minimize -nodesktop -nosplash -r wrapper' % Windows version (old approach only)
%
% If you want to use TraX protocol on Windows, or if the MEX function approach does not work,
% you can use the mwrapper executable found in trax reference implementation repository. In
% this case the command will look something like this:
%
% tracker_command = '<TODO: path to trax>\matlab\mwrapper.exe -I "<TODO: initialization script>" -U "<TODO: update script>"'
%
% For more details look at the instructions in the 

tracker_command = '<TODO: set a tracker executable command>';

% tracker_interpreter = []; % Set the interpreter used here as a lower case string. E.g. if you are using Matlab, write 'matlab'. (optional)

% tracker_linkpath = {}; % A cell array of custom library directories used by the tracker executable (optional)

% tracker_trax = true; % Using a TraX protocol for communication (default, optional)
