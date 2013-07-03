function [sequences] = load_sequences(directory, listfile)

global track_properties;

list_file = fullfile(directory, listfile);

sequences = cell(0);

mkpath(directory);

if ~exist(list_file, 'file') && ~isempty(track_properties.bundle)
    print_text('Downloading sequence bundle from "%s". This may take a while ...', track_properties.bundle);
    bundle = [tempname, '.zip'];
    try
        urlwrite(track_properties.bundle, bundle);
        unzip(bundle, directory);
		delete(bundle);
        list_file = fullfile(directory, 'list.txt');
    catch e
        print_text('Unable to retrieve sequence bundle. Follow the instructions in README.md to install it manually.');
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

    sequences{end+1} = create_sequence(sequence_name, sequence_directory);

end;

fclose(fid);
