function [resultfile] = pack_results(tracker, sequences, experiments)

files = cell(0);

for j = 1:length(experiments)
    experiment_directory = fullfile(tracker.directory, experiments{j}.name);
    if ~exist(experiment_directory, 'dir')
        continue;
    end;
    print_debug('Scanning "%s" ...', experiment_directory);
    for i = 1:length(sequences)
        sequence_directory = fullfile(experiment_directory, sequences{i}.name);
        if exist(sequence_directory, 'dir')
            files{end+1} = fullfile(sequence_directory); %#ok<AGROW>
            print_debug('Adding "%s" ...', sequence_directory);
        end;
    end;
end;

files{end+1} = write_manifest(tracker);

files{end+1} = benchmark_hardware(tracker);

%cd(get_global_variable('directory'));

filename = sprintf('%s-%s.zip', tracker.identifier, datestr(now, 30));

resultfile = fullfile(get_global_variable('directory'), filename);

resultsdir = fullfile(get_global_variable('directory'), 'results');

files = cellfun(@(f) relativepath(f, resultsdir), files, 'UniformOutput', false);

try    
    
    zip(filename, files, resultsdir);

catch e

    print_debug('Warning: error during creation of a result package: %s', e.message);
    resultfile = [];

end;

%cd(old_directory);


