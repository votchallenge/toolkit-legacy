function sequences = sequence_load(directory, varargin)
% sequence_load Load a set of sequences
%
% Create a cell array of new sequence structures for sequences, specified in a listing file.
%
% Input:
% - directory: Path to the directory with sequences.
% - varargin[List]: Name of the file that lists all the sequences. By default `list.txt` is used.
%
% Output:
% - sequences: A cell array of new sequence structures.

list = 'list.txt';

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'list'
            list = varargin{i+1};
        otherwise
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

list_file = fullfile(directory, list);

sequences = cell(0);

mkpath(directory);

bundle_url = get_global_variable('bundle');

if ~exist(list_file, 'file') && ~isempty(bundle_url)

    if strsuffix(bundle_url, '.zip')

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

    elseif strsuffix(bundle_url, '.json')
        listing = tempname;
        urlwrite(bundle_url, listing);
        meta = json_decode(fileread(listing));

        print_text('Downloading sequence dataset "%s" with %d sequences.', meta.name, numel(meta.sequences));
        
        slashes = strfind(bundle_url, '/');
        base_url = bundle_url(1:slashes(end));
        
        print_indent(1);
        
        for i = 1:numel(meta.sequences)
            sequence = meta.sequences{i};
            print_text('Downloading sequence "%s" ...', sequence.name);
            sequence_directory = fullfile(directory, sequence.name);
            %if exist(sequence_directory, 'dir')
            %    continue;
            %end;
            mkpath(sequence_directory);
            data = struct('name', sequence.name, 'fps', sequence.fps, 'format', 'default');
            data.channels = struct();

            if strncmp(sequence.annotations.url, 'http://', 7) || strncmp(sequence.annotations.url, 'https://', 8)
                annotations_url = sequence.annotations.url;
            else
                annotations_url = [base_url, sequence.annotations.url];
            end
            
            try
                bundle = [tempname, '.zip'];
                urlwrite(annotations_url, bundle);
                unzip(bundle, sequence_directory);
                delete(bundle);
            catch
                print_text('Unable to retrieve sequence bundle from the server. This is either a connection problem or the server is temporary offline.');
                return;
            end;

            channels = fieldnames(sequence.channels);
            
            for c = 1:numel(channels)
                channel = sequence.channels.(channels{c});
                channel_directory = fullfile(sequence_directory, channels{c});
                mkpath(channel_directory);
                if strncmp(channel.url, 'http://', 7) || strncmp(channel.url, 'https://', 8)
                    channel_url = channel.url;
                else
                    channel_url = [base_url, channel.url];
                end
                try
                    bundle = [tempname, '.zip'];
                    urlwrite(channel_url, bundle);
                    unzip(bundle, channel_directory);
                    delete(bundle);
                catch
                    print_text('Unable to retrieve sequence bundle from the server. This is either a connection problem or the server is temporary offline.');
                    return;
                end;

                if isfield(channel, 'pattern')
                    data.channels.(channels{c}) = [channels{c}, filesep, channel.pattern];
                else
                    data.channels.(channels{c}) = [channels{c}, filesep];
                end
            end
            
            writestruct(fullfile(sequence_directory, 'sequence'), data);
            
        end
        
        list_file = fullfile(directory, 'list.txt');
        % Save list file
        fid = fopen(list_file, 'w');
        for i = 1:numel(meta.sequences)
            fprintf(fid, '%s\n', meta.sequences{i}.name);
        end
        fclose(fid);
        
        print_indent(-1);

    else
        error('Unknown dataset type!');
    end;

end;

fid = fopen(list_file, 'r');

while true
    sequence_name = fgetl(fid);
    if sequence_name == -1
        break;
    end

    if exist(fullfile(directory, sequence_name, 'sequence'), 'file')
        sequence_path = fullfile(directory, sequence_name, 'sequence');
    elseif exist(fullfile(directory, sequence_name), 'dir')
        sequence_path = fullfile(directory, sequence_name);
    else
        continue;
    end;

    print_debug('Loading sequence %s', sequence_name);

    sequences{end+1} = sequence_create(sequence_path); %#ok<AGROW>

end;

fclose(fid);
