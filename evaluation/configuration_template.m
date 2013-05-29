
global track_properties;

track_properties.directory = '<TODO: set a working directory for sequences and results>';

% Enable more verbose output
% track_properties.debug = 1;

% Disable result caching
% track_properties.cache = 0;

% Disable result packaging
% track_properties.pack = 0;

tracker_identifier = '<TODO: set a tracker identifier>';

tracker_command = '<TODO: set a tracker executable command>';

% For classical executables this is usually just a full path to the executable plus
% some optional arguments
%
% tracker_command = fullfile(pwd, '..', 'examples', 'c', 'track_dummy');
%
% For MATLAB scripts use the following template:
% tracker_command = '<TODO: path to Matlab installation>/bin/matlab -nodesktop -nosplash -r MS_Tracker_Example'

