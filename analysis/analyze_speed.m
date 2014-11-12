function [normalized, original] = analyze_speed(experiments, trackers, sequences, varargin)

cache = fullfile(get_global_variable('directory'), 'cache');

for i = 1:2:length(varargin)
    switch lower(varargin{i})          
        case 'cache'
            cache = varargin{i+1};                   
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

experiments_hash = md5hash(strjoin(sort(cellfun(@(x) x.name, experiments, 'UniformOutput', false)), '-'), 'Char', 'hex');
sequences_hash = md5hash(strjoin(sort(cellfun(@(x) x.name, sequences, 'UniformOutput', false)), '-'), 'Char', 'hex');
trackers_hash = md5hash(strjoin(sort(cellfun(@(x) x.identifier, trackers, 'UniformOutput', false)), '-'), 'Char', 'hex');
mkpath(fullfile(cache, 'speed'));

cache_file = fullfile(cache, 'speed', sprintf('%s_%s_%s.mat', experiments_hash, trackers_hash, sequences_hash));

if exist(cache_file, 'file') 
        normalized = [];
        original = [];
        load(cache_file);
        if ~isempty(normalized) && ~isempty(original)   
            print_text('Loading speed results from cache.');
            return;
        end;
end;
    
normalized = nan(length(experiments), length(trackers), length(sequences));
original = nan(length(experiments), length(trackers), length(sequences));

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

			if size(times, 1) == 1
				times = repmat(times, experiment_sequences{s}.length, 1);
			end

			if size(times, 2) < repeat
				times = cat(2, times, zeros(experiment_sequences{s}.length, repeat - size(times, 2)));
			end;

            valid = any(times > 0, 1) & ~isnan(reliability)';
            average_speed = mean(times(:, valid), 1)';   
            average_original = mean(average_speed);
            
            if isfield(trackers{t}, 'performance')           
                average_normalized = mean(normalize_speed(average_speed, failures(valid), trackers{t}, experiment_sequences{s}));
            else
				average_normalized = NaN;
                print_debug('Warning: No performance profile for tracker %s.', trackers{t}.identifier);
            end;

            if isnan(average_normalized) || average_normalized == 0
                normalized(e, t, s) = NaN;
            else
                normalized(e, t, s) = 1 / average_normalized;
            end;

            if isnan(average_original) || average_original == 0
                original(e, t, s) = NaN;
            else
                original(e, t, s) = 1 / average_original;
            end;            
            
        end;

    end;

	print_indent(-1);

end;

save(cache_file, 'normalized', 'original');
