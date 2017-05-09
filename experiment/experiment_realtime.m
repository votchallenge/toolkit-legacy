function [files, metadata] = experiment_realtime(tracker, sequence, directory, parameters, scan)

files = {};
metadata.completed = true;
cache = get_global_variable('experiment_cache', true);
silent = get_global_variable('experiment_silent', false);

defaults = struct('repetitions', 1, 'failure_overlap', 0, ...
    'default_fps', 25, 'override_fps', false, 'critical', true, ...
    'grace', 0);
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

    data = tracker_run(tracker, @callback, data);

    times(:, i) = data.timing;
    write_trajectory(result_file, data.result);
    csvwrite(time_file, times);

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

% Handle initial frame (initialize for the first time)
if isempty(state.region)
    region = data.sequence.initialize(data.sequence, data.index, data.context);
    image = get_image(data.sequence, data.index);
    data.time = 0;
	data.offset = 0;
    data.grace = data.context.grace;
    return;
end;

% Handle grace period
if data.grace > 0
    data.time = data.time + 1000 / data.fps;
else
    data.time = data.time + max(1000 / data.fps, state.time * 1000);
end;

previous = data.index;
current = round(floor(data.time * data.fps) / 1000) + data.offset;

data.timing(previous) = state.time;

failed = 0;

% Store initialization
if ~data.initialized
    data.result{previous} = 1;
    data.region = state.region;
    data.initialized = true;
else

    for i = previous:min(data.sequence.length, current-1)

        o = region_overlap(data.region, get_region(data.sequence, i));

        if o(1) <= data.context.failure_overlap
            failed = i;
            break;
        end;

        data.result{i} = data.region;
    end

    if failed > 0
        if data.context.critical
            data.result{failed} = 2;
            data.index = current + 1;
        else
            data.result{failed} = 2;
            data.index = failed + 1;
        end
		data.time = 0;
		data.offset = data.index - 1;

		% Should be initalzed after the end of the sequence
		if data.index > data.sequence.length
		    return;
		end

        region = data.sequence.initialize(data.sequence, data.index, data.context);
        image = get_image(data.sequence, data.index);
        data.initialized = false;
        data.grace = data.context.grace;
        return;
    end

	% Tracked over the end of the sequence
    if current > data.sequence.length
        return;
    end

    data.result{current} = state.region;
	data.region = state.region;

end;

% Tracked over the end of the sequence
if current > data.sequence.length
    return;
end

o = region_overlap(state.region, get_region(data.sequence, current));

if o(1) <= data.context.failure_overlap

        data.result{current} = 2;
        data.index = current + 1;
		data.time = 0;
		data.offset = data.index - 1;

        % Should be initalzed after the end of the sequence
        if data.index > data.sequence.length
            return;
        end

        region = get_region(data.sequence, data.index);
        image = get_image(data.sequence, data.index);
        data.initialized = false;
        data.grace = data.context.grace;
        return;
end;

data.index = current + 1;

% At the end of sequence
if data.index > data.sequence.length
    return;
end

image = get_image(data.sequence, data.index);

end

