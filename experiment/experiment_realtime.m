function [files, metadata] = experiment_realtime(tracker, sequence, directory, parameters, scan)

files = {};
metadata.completed = true;
cache = get_global_variable('experiment_cache', true);
silent = get_global_variable('experiment_silent', false);

defaults = struct('repetitions', 1, 'failure_overlap', 0, ...
    'default_fps', 25, 'override_fps', false, 'critical', true, ...
    'grace', 0, 'skip_initialize', 1, 'realtime_type', 'real');
context = struct_merge(parameters, defaults);
metadata.deterministic = false;

if context.failure_overlap < 0
    error('Illegal failure overlap');
end;

if context.default_fps <= 0
    error('Illegal FPS specification');
end;

time_file = fullfile(directory, sprintf('%s_time.txt', sequence.name));

times = zeros(sequence.length, context.repetitions);

if ~scan && cache && exist(time_file, 'file')
    times = csvread(time_file);
end;

r = context.repetitions;

if isfield(tracker, 'metadata') && isfield(tracker.metadata, 'deterministic') && tracker.metadata.deterministic
    r = 1;
end

check_deterministic = ~(scan && nargout < 2); % Ensure faster execution when we only want a list of files by ommiting determinisim check.

for i = 1:r

    result_file = fullfile(directory, sprintf('%s_%03d.txt', sequence.name, i));

    if cache && exist(result_file, 'file')
        files{end+1} = result_file; %#ok<AGROW>
        values = dir(fullfile(directory, sprintf('%s_%03d_*.value', sequence.name, i)));
        files(end+1:end+length(values)) = cellfun(@(x) fullfile(directory, x.name), num2cell(values), 'UniformOutput', false);
        continue;
    end;

    if check_deterministic && i == 4 && is_deterministic(sequence, 3, directory)
        if ~silent
            print_debug('Detected a deterministic tracker, skipping remaining trials.');
        end;
        metadata.deterministic = true;
        break;
    end;

    if scan
        metadata.completed = false;
        continue;
    end;

    print_indent(1);

    print_text('Repetition %d', i);

    context.repetition = i;

    data.sequence = sequence;
    data.bounds = [sequence.width, sequence.height] - 1;
    data.index = 1;
    data.context = context;
    data.time = 0;

    if isfield(sequence.properties, 'fps') && ~context.override_fps
        data.fps = sequence.properties.fps;
    else
        data.fps = context.default_fps;
    end

    data.result = repmat({0}, sequence.length, 1);
    data.timing = nan(sequence.length, 1);
    data.initialized = false;
    data.properties = properties_create(sequence);
    data.channels = {};
    
    data = tracker_run(tracker, @callback, data);

    times(:, i) = data.timing;
    write_trajectory(result_file, data.result);
    csvwrite(time_file, times);
    properties_save(directory, sprintf('%s_%03d', sequence.name, i), data.properties);
    
    files{end+1} = result_file; %#ok<AGROW>
    values = dir(fullfile(directory, sprintf('%s_%03d_*.value', sequence.name, i)));
    files(end+1:end+length(values)) = cellfun(@(x) fullfile(directory, x.name), num2cell(values), 'UniformOutput', false);

    print_indent(-1);
end;

if exist(time_file, 'file')
    files{end+1} = time_file;
else
    metadata.completed = false;
end;

end

function [image, region, properties, data] = callback(state, data)

region = [];
image = [];
properties = struct();

if isempty(data.channels)
    if ~all(ismember(state.channels, fieldnames(data.sequence.channels)));
        error('Sequence does not contain all channels required by the tracker.');
    end;
    data.channels = state.channels;
end;

% Handle initial frame (initialize for the first time)
if isempty(state.region)
    region = data.sequence.initialize(data.sequence, data.index, data.context);
    image = sequence_get_image(data.sequence, data.index, data.channels);
    data.time = 0;
	data.offset = 0;
    data.grace = data.context.grace;
    return;
end;

% Handle grace period
if data.grace > 0
    data.time = data.time + 1000 / data.fps;
    data.grace = data.grace - 1;
else
    data.time = data.time + max(1000 / data.fps, state.time * 1000);
end;

previous = data.index;
current = round(floor(data.time * data.fps) / 1000) + data.offset;

data.timing(previous) = state.time;
data.properties = properties_set(data.properties, previous, state.properties);

failed = 0;

% Store initialization
if ~data.initialized
    data.result{previous} = 1;
    data.initialized = true;
else
    if strcmpi(data.context.realtime_type, 'real')
        % NOTE : this assumes 0-motion model, in "real" algorithm the data.region would
        %        be computed using motion model continuously for each frame in "real-time" fps
        %        and the state.region used to update this model

        for i = previous:min(data.sequence.length, current-1)
            o = region_overlap(data.region, sequence_get_region(data.sequence, i), data.bounds);
            if o(1) <= data.context.failure_overlap
                failed = i;
                break;
            end
            data.result{i} = data.region;
        end

        if current <= data.sequence.length
            o = region_overlap(state.region, sequence_get_region(data.sequence, current), data.bounds);
            if o(1) <= data.context.failure_overlap
                failed = current;
            else
                data.result{current} = state.region;
            end
        end
    else   % realtime_type = 'delayed' by default
        o = region_overlap(state.region, sequence_get_region(data.sequence, previous), data.bounds);
        if o(1) <= data.context.failure_overlap
            failed = previous;
        else
            % NOTE : state.region here can be also replaced with a motion model
            range = previous:min(data.sequence.length, current);
            for i = range
                data.result{i} = state.region;
            end
        end;
    end
end

if failed > 0
    if data.context.critical
        data.result{failed} = 2;
        data.index = current + data.context.skip_initialize;
    else
        data.result{failed} = 2;
        data.index = failed + data.context.skip_initialize;
    end
    data.time = 0;
    data.offset = data.index - 1;

    % Should be initalzed after the end of the sequence
    if data.index > data.sequence.length
        return;
    end

    region = data.sequence.initialize(data.sequence, data.index, data.context);
    data.initialized = false;
    data.grace = data.context.grace;
else
    data.region = state.region;
    data.index = current + 1;

    % At the end of sequence
    if data.index > data.sequence.length
        return;
    end

end

image = sequence_get_image(data.sequence, data.index, data.channels);

end

