
error('Tracker not configured!'); % Remove this line after proper configuration

% The human readable label for the tracker, used to identify the tracker in reports
% If not set, it will be set to the same value as identifier
% It does not have to be unique, but it is best that it is.
tracker_label = [];

% For classical executables this is usually just a full path to the executable plus
% some optional arguments
%
% tracker_command = fullfile(pwd, '..', 'examples', 'c', 'static');
%
% For MATLAB scripts use the following template:
% 
% tracker_command = '<TODO: path to Matlab installation>/bin/matlab -wait -nodesktop -nosplash -r wrapper' % Windows version
% tracker_command = '<TODO: path to Matlab installation>/bin/matlab -nodesktop -nosplash -r wrapper' % Linux and OSX version

tracker_command = '<TODO: set a tracker executable command>';

tracker_linkpath = {}; % A cell array of custom library directories used by the tracker executable.

