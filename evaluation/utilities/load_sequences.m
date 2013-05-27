function [sequences] = load_sequences(directory)

global track_properties;

list_file = fullfile(directory, 'list.txt');

if ~exist(list_file, 'file') && ~isempty(track_properties.bundle)
    bundle = tempname;
    urlwrite(track_properties.bundle, bundle);
    unzip(bundle, directory);
end;

fid = fopen(list_file, 'r');

sequences = cell();

while true
    sequence_name = fgetl(fid);
    if sequence_name == -1
        break;
    end

    sequence_directory = fullfile(directory, sequence_name);

    if ~exist(sequence_directory, 'dir') 
        continue;
    end;

    sequences{end+1} = track_create_sequence(sequence_name, sequence_directory);

end;

fclose(fid);
