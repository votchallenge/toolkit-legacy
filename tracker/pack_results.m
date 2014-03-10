function [resultfile] = pack_results(tracker, sequences, experiments)

files = cell(0);

for j = 1:length(experiments)
    experiment_directory = fullfile(get_global_variable('directory'), experiments{j}.name);
    if ~exist(experiment_directory, 'dir')
        continue;
    end;
    print_debug('Scanning "%s" ...', experiment_directory);
    for i = 1:length(sequences)
        sequence_directory = fullfile(experiment_directory, sequences{i}.name);
        if exist(sequence_directory, 'dir')
            files{end+1} = fullfile(experiments{j}.name, sequences{i}.name); %#ok<AGROW>
            print_debug('Adding "%s" ...', sequence_directory);
        end;
    end;
end;

files{end+1} = relativepath(write_manifest(tracker), tracker.directory);

old_directory = pwd;

cd(get_global_variable('directory'));

filename = sprintf('%s-%s.zip', tracker.identifier, datestr(now, 30));

resultfile = fullfile(get_global_variable('directory'), filename);

try

    zip(filename, files, tracker.directory);

catch e

    print_debug('Warning: problem with creating a result package: %s', e.message);
    resultfile = [];

end;

cd(old_directory);


