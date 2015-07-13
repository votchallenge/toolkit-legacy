function sequences = load_sequences(directory, varargin)
% load_sequences Load a set of sequences
%
% Create a cell array of new sequence structures for sequences, specified in a listing file.
%
% Input:
% - directory: Path to the directory with sequences.
% - varargin[List]: Name of the file that lists all the sequences. By default `list.txt` is used.
% - varargin[Dummy]: Create the sequence structures without checking if all the images exist.
%
% Output:
% - sequences: A cell array of new sequence structures.

list = 'list.txt';
dummy = false;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'list'
            list = varargin{i+1};
        case 'dummy'
            dummy = varargin{i+1};            
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

list_file = fullfile(directory, list);

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
        print_text('Unable to retrieve sequence bundle from the server. This is either a connection problem or the server is temporary offline.');
        print_text('Please try to download the bundle manually from %s and uncompress it to %s', bundle_url, directory);
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

    print_debug('Loading sequence %s', sequence_name);
    
    sequences{end+1} = create_sequence(sequence_directory, 'dummy', dummy); %#ok<AGROW>

end;

fclose(fid);
