
set_global_variable('directory', '<TODO: set a working directory for sequences and results>');

% Enable more verbose output
% set_global_variable('debug', 1);

% Disable result caching
% set_global_variable('cache', 0);

% Disable result packaging
% set_global_variable('pack', 0);

tracker_identifier = '<TODO: set a tracker identifier>';

tracker_command = '<TODO: set a tracker executable command>';

tracker_linkpath = {}; % A cell array of custom library directories used by the tracker executable.

% For classical executables this is usually just a full path to the executable plus
% some optional arguments
%
% tracker_command = fullfile(pwd, '..', 'examples', 'c', 'static');
%
% For MATLAB scripts use the following template:
% 
% tracker_command = '<TODO: path to Matlab installation>/bin/matlab -wait -nodesktop -nosplash -r wrapper' % Windows version
% tracker_command = '<TODO: path to Matlab installation>/bin/matlab -nodesktop -nosplash -r wrapper' % Linux and OSX version
