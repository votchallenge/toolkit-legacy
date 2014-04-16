function [sequences] = load_sequences(directory, listfile)

list_file = fullfile(directory, listfile);

sequences = cell(0);

mkpath(directory);

bundle_url = get_global_variable('bundle');

if ~exist(list_file, 'file') && ~isempty(bundle_url)
    print_text('Downloading sequence bundle from "%s". This may take a while ...', bundle_url);
    bundle = [tempname, '.zip'];
    try
        urlwrite(bundle_url, bundle);
        unzip(bundle, directory);
		delete(bundle);
        list_file = fullfile(directory, 'list.txt');
    catch
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
