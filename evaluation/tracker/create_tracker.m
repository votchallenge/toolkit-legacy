function [tracker] = create_tracker(identifier, result_directory)

if isempty(result_directory)    
    result_directory = fullfile(get_global_variable('directory'), 'results', identifier);
end;

mkpath(result_directory);

if exist(['tracker_' , identifier]) ~= 2
    print_debug('WARNING: No configuration for tracker %s found', identifier);
    tracker = struct('identifier', identifier, 'command', [], ...
        'directory', result_directory, 'linkpath', []);
    return;
    %error('Configuration for tracker %s does not exist.', identifier);
end;

tracker_configuration = str2func(['tracker_' , identifier]);
tracker_configuration();

tracker = struct('identifier', identifier, 'command', tracker_command, ...
        'directory', result_directory, 'linkpath', {tracker_linkpath});

tracker.run = @run_tracker;
