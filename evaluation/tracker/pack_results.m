function [resultfile] = pack_results(tracker, sequences, experiments)

global track_properties;

files = cell(0);

for j = 1:length(experiments)
    experiment_directory = fullfile(tracker.directory, experiments{j});
    if ~exist(experiment_directory, 'dir')
        continue;
    end;
    print_debug('Scanning "%s" ...', experiment_directory);
    for i = 1:length(sequences)
        sequence_directory = fullfile(experiment_directory, sequences{i}.name);
        if exist(sequence_directory, 'dir')
            files{end+1} = fullfile(experiments{j}, sequences{i}.name);
            print_debug('Adding "%s" ...', sequence_directory);
            %files = [files; recursive_dir(sequence_directory)];
        end;
    end;
end;

files{end+1} = relativepath(write_manifest(tracker), tracker.directory);

old_directory = pwd;

cd(track_properties.directory);

filename = sprintf('%s-%s.zip', tracker.identifier, datestr(now, 30));

resultfile = fullfile(track_properties.directory, filename);

try

    zip(filename, files, tracker.directory);

catch e

    resultfile = [];

end;

cd(old_directory);


