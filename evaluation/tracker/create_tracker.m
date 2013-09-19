function [tracker] = create_tracker(identifier, result_directory)

if exist(['tracker_' , identifier]) ~= 2
    error('Configuration for tracker %s does not exist.', identifier);
end;

tracker_configuration = str2func(['tracker_' , identifier]);
tracker_configuration();


mkpath(result_directory);

tracker = struct('identifier', identifier, 'command', tracker_command, ...
        'directory', result_directory, 'linkpath', {tracker_linkpath});

tracker.run = @run_tracker;
