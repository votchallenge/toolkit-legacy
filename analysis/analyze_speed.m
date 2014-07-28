function [speeds, normalized] = analyze_speed(experiments, trackers, sequences, varargin)

speeds = nan(length(experiments), length(trackers), length(sequences));
normalized = false(length(experiments), length(trackers), length(sequences));

repeat = get_global_variable('repeat', 1);

for e = 1:numel(experiments)

    experiment = experiments{e};

    print_text('Speed analysis for experiment %s ...', experiment.name);

    print_indent(1);

	experiment_sequences = convert_sequences(sequences, experiment.converter);

    for t = 1:length(trackers)

        directory = fullfile(trackers{t}.directory, experiment.name);

		print_text('Tracker %s ...', trackers{t}.identifier);

        for s = 1:length(experiment_sequences)

            reliability = nan(repeat, 1);
			failures = cell(repeat, 1);

            for j = 1:repeat

                result_file = fullfile(directory, experiment_sequences{s}.name, sprintf('%s_%03d.txt', experiment_sequences{s}.name, j));

                try 
                    trajectory = read_trajectory(result_file);
                catch
                    continue;
                end;

                [reliability(j), failures{j}] = estimate_failures(trajectory, experiment_sequences{s});

            end;            
            
			times_file = fullfile(directory, experiment_sequences{s}.name, ...
                sprintf('%s_time.txt', experiment_sequences{s}.name));

			if ~exist(times_file, 'file')
				print_debug('Warning: Missing time results for tracker %s, sequence %s.', trackers{t}.identifier, experiment_sequences{s}.name);
				continue;
			end;

            times = csvread(times_file);

			if size(times, 2) < repeat
				times = cat(2, times, zeros(experiment_sequences{s}.length, repeat - size(times, 2)));
			end;

            valid = any(times > 0, 1) & ~isnan(reliability)';
            average_speed = mean(times(:, valid), 1)';   
            reliability = reliability(valid);

            if isfield(trackers{t}, 'performance')           
                average_speed = mean(normalize_speed(average_speed, failures(valid), trackers{t}, experiment_sequences{s}));
                normalized(e, t, s) = true;
            else
				average_speed = mean(average_speed);
                print_debug('Warning: No performance profile for tracker %s.', trackers{t}.identifier);
            end;

            if isnan(average_speed) || average_speed == 0
                speeds(e, t, s) = NaN;
            else
                speeds(e, t, s) = 1 / average_speed;
            end;

        end;

    end;

	print_indent(-1);

end;
