function result = analyze_speed(experiments, trackers, sequences, varargin)
% analyze_speed Perform speed analysis
%
% Perform speed analysis on a set of experiments, trackers, and sequences. Returns 
% normalized and raw average speed.
%
% Input:
% - experiments (cell): A cell array of valid experiment structures.
% - trackers (cell): A cell array of valid tracker descriptors.
% - sequences (cell): A cell array of valid sequence descriptors.
%
% Output:
% - result (struct):
%     - normalized (double matrix): Normalized speed.
%     - original (double matrix): Raw speed.
%


print_text('Performing speed analysis ...');
    
normalized = nan(length(experiments), length(trackers), length(sequences));
original = nan(length(experiments), length(trackers), length(sequences));

result = struct('normalized', normalized, 'original', original);

result = iterate(experiments, trackers, sequences, 'iterator', @speed_iterator, 'context', result);

end

function context = speed_iterator(event, context)
% speed_iterator Internal iterator function
%
% Input:
% - event (structure): Iteration event.
% - context (structure): Iteration context.
%
% Output:
% - context (structure): Iterator context.
%


    switch (event.type)
        case 'experiment_enter'
            
            print_debug('Experiment %s', event.experiment.name);

            print_indent(1);       
        case 'experiment_exit'

            print_indent(-1);

        case 'tracker_enter'
            
            print_debug('Tracker %s', event.tracker.identifier);

            print_indent(1);  
            
        case 'tracker_exit'

            print_indent(-1);
            
        case 'sequence_enter'
            
            directory = fullfile(event.tracker.directory, event.experiment.name);
            
            print_debug('Sequence %s', event.sequence.name);

            repeat = event.experiment.parameters.repetitions;
            
            reliability = nan(repeat, 1);
			failures = cell(repeat, 1);

            for j = 1:repeat

                result_file = fullfile(directory, event.sequence.name, sprintf('%s_%03d.txt', event.sequence.name, j));

                try 
                    trajectory = read_trajectory(result_file);
                catch
                    continue;
                end;

                [reliability(j), failures{j}] = estimate_failures(trajectory, event.sequence);

            end;            
            
			times_file = fullfile(directory, event.sequence.name, ...
                sprintf('%s_time.txt', event.sequence.name));

			if ~exist(times_file, 'file')
				print_debug('Warning: Missing time results for tracker %s, sequence %s.', event.tracker.identifier, event.sequence.name);
				return;
			end;

            times = csvread(times_file);

			if size(times, 1) == 1
				times = repmat(times, event.sequence.length, 1);
			end

			if size(times, 2) < repeat
				times = cat(2, times, zeros(event.sequence.length, repeat - size(times, 2)));
			end;

            valid = any(times > 0, 1) & ~isnan(reliability)';
            average_speed = mean(times(:, valid), 1)';
            average_original = mean(average_speed);
            
            if isfield(event.tracker, 'performance')           
                average_normalized = mean(normalize_speed(average_speed, ...
                    failures(valid), event.experiment.parameters.skip_initialize, event.tracker, event.sequence));
            else
				average_normalized = NaN;
                print_debug('Warning: No performance profile for tracker %s.', event.tracker.identifier);
            end;

            if isnan(average_normalized) || average_normalized == 0
                context.normalized(event.experiment_index, event.tracker_index, event.sequence_index) = NaN;
            else
                context.normalized(event.experiment_index, event.tracker_index, event.sequence_index) = 1 / average_normalized;
            end;

            if isnan(average_original) || average_original == 0
                context.original(event.experiment_index, event.tracker_index, event.sequence_index) = NaN;
            else
                context.original(event.experiment_index, event.tracker_index, event.sequence_index) = 1 / average_original;
            end;
            
    end;

end
