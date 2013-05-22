function [tracker] = track_create_tracker(command)

tracker = struct('command', command);

%For MATLAB/Octave:
%tracker = struct('command', ['/path/to/matlab/bin/matlab -nodesktop -nosplash -r ' command]);



