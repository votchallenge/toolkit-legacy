function [files, metadata] = tracker_evaluate(tracker, sequence, directory, varargin)
% tracker_evaluate Evaluates a tracker on a given sequence for experiment
%
% The core function of experimental evaluation. This function can perform various
% types of experiments or result gathering. The data is stored to the specified
% directory.
%
% Experiment types:
% - supervised: Repeats running a tracker on a given sequence for a number of
%   times, taking into account its potential deterministic nature and
%   various properties of experiments.
%
% Input:
% - tracker (struct): Tracker structure.
% - sequence (struct): Sequence structure.
% - directory (string): Directory where the results are saved.
% - varargin[Type] (string): Execution context structure. This structure contains
%   parameters of the execution.
% - varargin[Parameters] (struct): Execution parameters structure. This structure contains
%   parameters of the execution.
% - varargin[Scan] (boolean): Do not evaluate the tracker but simply scan the directory
%   for files that are generated and return their list.
%
% Output:
% - files (cell): An array of files that were generated during the evaluation.
% - completed (boolean): Was the evaluation completed.

    scan = false;
    type = 'supervised';
    parameters = struct();
    files = {};
    metadata.completed = true;
    cache = get_global_variable('cache', 0);
    silent = false;

    for j=1:2:length(varargin)
        switch lower(varargin{j})
            case 'parameters', parameters = varargin{j+1};
            case 'type', type = varargin{j+1};
            case 'scan', scan = varargin{j+1};
            case 'silent', silent = varargin{j+1};
            otherwise, error(['unrecognized argument ' varargin{j}]);
        end
    end

    mkpath(directory);

    % In case of scanning we enable chaching so that results do not get re-evaluated
    if scan
        cache = true;
    end;

    check_deterministic = ~(scan && nargout < 2); % Ensure faster execution when we only want a list of files by ommiting determinisim check.

    switch type
    case {'supervised', 'unsupervised'}

        defaults = struct('repetitions', 15, 'skip_labels', {{}}, 'skip_initialize', 0, 'failure_overlap', -1);
        context = struct_merge(parameters, defaults);
        metadata.deterministic = false;

        if strcmp(type, 'unsupervised')
            context.failure_overlap = -1;
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

            [trajectory, time] = tracker.run(tracker, sequence, context);

            print_indent(-1);

            if numel(time) ~= sequence.length
                times(:, i) = mean(time);
            else
                times(:, i) = time;
            end

            if ~isempty(trajectory)
                write_trajectory(result_file, trajectory);
		        csvwrite(time_file, times);
            end;
        end;

        if exist(time_file, 'file')
            files{end+1} = time_file;
        else
            metadata.completed = false;
        end;

    case 'chunked'

        defaults = struct('repetitions', 15, 'skip_labels', {{}}, 'skip_initialize', 0, 'failure_overlap',  -1, 'chunk_length', 50);
        context = struct_merge(parameters, defaults);
        metadata.deterministic = false;

        [chunks, chunk_offset] = sequence_fragment(sequence, context.chunk_length);

        time_file = fullfile(directory, sprintf('%s_time.txt', sequence.name));

        times = zeros(sequence.length, context.repetitions);

        if ~scan && cache && exist(time_file, 'file')
            times = csvread(time_file);
        end;

        for i = 1:context.repetitions

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

            trajectory = cell(sequence.length, 1);
            time = zeros(sequence.length, 1);

            for c = 1:numel(chunks)

                [chunk_trajectory, chunk_time] = tracker.run(tracker, chunks{c}, context);

                trajectory(chunk_offset(c):chunk_offset(c)+numel(chunk_trajectory)-1) = chunk_trajectory;
                time(chunk_offset(c):chunk_offset(c)+numel(chunk_trajectory)-1) = chunk_time;

            end;

            print_indent(-1);

            if numel(time) ~= sequence.length
                times(:, i) = mean(time);
            else
                times(:, i) = time;
            end

            if ~isempty(trajectory)
                write_trajectory(result_file, trajectory);
		        csvwrite(time_file, times);
            end;
        end;

    otherwise, error(['unrecognized type ' type]);

    end

end
