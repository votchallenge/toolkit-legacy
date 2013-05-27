function [tracker] = track_create_tracker(identifier, command, result_directory)

mkpath(result_directory);

tracker = struct('identifier', identifier, 'command', command, 'directory', result_directory);
