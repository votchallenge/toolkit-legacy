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

print_text('Performing speed analysis ...');

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

result = struct('normalized', normalized, 'original', original);

result = iterate(experiments, trackers, sequences, 'iterator', @speed_iterator, 'context', result);

normalized = result.normalized;
original = result.original;

save(cache_file, 'normalized', 'original');

end

function context = speed_iterator(event, context)

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

            repeat = event.experiment.parameters.repeat;
            
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
                average_normalized = mean(normalize_speed(average_speed, failures(valid), event.experiment.parameters.skip_initialize, event.tracker, event.sequence));
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
