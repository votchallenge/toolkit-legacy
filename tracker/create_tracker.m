function [tracker] = create_tracker(identifier)

result_directory = fullfile(get_global_variable('directory'), 'results', identifier);

mkpath(result_directory);

if exist(['tracker_' , identifier]) ~= 2 %#ok<EXIST>
    print_debug('WARNING: No configuration for tracker %s found', identifier);
    tracker = struct('identifier', identifier, 'command', [], ...
        'directory', result_directory, 'linkpath', [], 'label', identifier);
    return;
    %error('Configuration for tracker %s does not exist.', identifier);
end;

tracker_label = [];

tracker_configuration = str2func(['tracker_' , identifier]);
tracker_configuration();

if isempty(tracker_label)
    tracker_label = identifier;
end;
    
tracker_label = strtrim(tracker_label);

tracker = struct('identifier', identifier, 'command', tracker_command, ...
        'directory', result_directory, 'linkpath', {tracker_linkpath}, ...
        'label', tracker_label);

if exist('tracker_trax', 'var') && tracker_trax
    trax_executable = get_global_variable('trax_client', '');
    if isempty(trax_executable) && ~isempty(tracker.command)
        error('TraX support not available');
    end;
    tracker.run = @trax_wrapper;
    tracker.trax = true;
else
    tracker.run = @system_wrapper;
    tracker.trax = false;
end;
