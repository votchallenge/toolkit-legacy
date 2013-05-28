function [sequences] = load_sequences(directory)

global track_properties;

list_file = fullfile(directory, 'list.txt');

sequences = cell();

if ~exist(list_file, 'file') && ~isempty(track_properties.bundle)
    print_text('Downloading sequence bundle from "%s". This may take a while ...', track_properties.bundle);
    bundle = tempname;
    try
        urlwrite(track_properties.bundle, bundle);
        unzip(bundle, directory);
    catch e
        print_text('Unable to retreive sequence bundle. Follow the instructions in README.md to install it manually.');
        return;
    end;
end;

fid = fopen(list_file, 'r');

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
