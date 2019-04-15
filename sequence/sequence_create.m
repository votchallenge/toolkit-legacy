function [sequence] = sequence_create(sequence_path, varargin)
% sequence_create Create a new sequence descriptor
%
% Create a new sequence structure by loading the information from the directory.
%
% Input:
% - sequence_path: Path to the sequence directory or to the sequence metadata file.
% - varargin[Name]: Name of the sequence. By default the name of the directory is taken as the name of the sequence.
%
% Output:
% - sequence: A new sequence structure.

metadata = struct();

if exist(sequence_path, 'file') == 2
    metadata = readstruct(sequence_path);
	directory = fileparts(sequence_path);
else
    directory = sequence_path;
end;

default_channel = 'color';

if isfield(metadata, 'format') && ~strcmpi(metadata.format, 'default')
    sequence_function = str2func(['sequence_create_', metadata.format]);
    sequence = sequence_function(directory, metadata);
    sequence.format = metadata.format;
    return;
end

if isfield(metadata, 'channels') && isfield(metadata.channels, 'default')
   default_channel = metadata.channels.default;
end

% At the moment we only load default channel, multi-channel sequences will
% be supported someday

channels = struct();

if ~isfield(metadata, 'channels') || ~isfield(metadata.channels, default_channel)
	if all(size(dir([directory, '/*.jpg'])))
		mask = '%08d.jpg';
	elseif all(size(dir([directory, '/*.png'])))
		mask = '%08d.png';
	end;

    channels.(default_channel) = fullfile(directory, mask);

else

    fields = fieldnames(metadata.channels);

    for i=1:numel(fields)

        channel = fields{i};

        if strcmp(channel, 'default')
            continue;
        end;

        [sdir, sfile, sext] = fileparts(metadata.channels.(channel));

        channel_directory = fullfile(directory, sdir);

        if isempty(sfile)
            mask = '%08d.jpg';
        else
            mask = [sfile, sext];
        end

        channels.(channel) = fullfile(channel_directory, mask);

    end

end;

[~, name] = fileparts(directory);

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'name'
            name = varargin{i+1};
        otherwise
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

if isempty(mask)
    error('Unkown file ending for sequence frames');
end;

sequence = struct('name', name, 'directory', directory, ...
        'channels', channels, 'length', 0, 'default', default_channel, ...
        'file', 'groundtruth.txt');

sequence.groundtruth = read_trajectory(fullfile(sequence.directory, sequence.file));

sequence.initialize = @(sequence, index, context) sequence_get_region(sequence, index);

sequence.length = numel(sequence.groundtruth);

sequence.indices = 1:sequence.length;

if sequence.length < 1
    error('Empty sequence: %s', name);
end;

imdata = imread(sequence_get_image(sequence, 1, default_channel));

[height, width, colorchannels] = size(imdata);

sequence.grayscale = colorchannels == 1 || isequal(imdata(:, :, 1), ...
		imdata(:, :, 2), imdata(:, :, 3));

sequence.width = width;
sequence.height = height;

sequence.tags.names = {};
tagdata = false(sequence.length, 0);

% Supporting legacy suffix
tagfiles = [dir(fullfile(directory, '*.label'))', dir(fullfile(directory, '*.tag'))'];

for file = tagfiles

    try
        data = csvread(fullfile(directory, file.name));
    catch e
        e.message
        continue
    end;

    if size(data, 1) > sequence.length || size(data, 2) ~= 1
        print_debug('Tag file does not have correct size');
        continue;
    end;

    if size(data, 1) < sequence.length
        data(end+1:sequence.length) = 0;
    end;

    sequence.tags.names{end+1} = file.name(1:max(strfind(file.name, '.'))-1);
    tagdata = cat(2, tagdata, data > 0);

end;

sequence.tags.data = tagdata;

sequence.values.names = {};
valuesdata = false(sequence.length, 0);

for file = dir(fullfile(directory, '*.value'))'

    try
        data = csvread(fullfile(directory, file.name));
    catch e
        e.message
        continue
    end;

    if size(data, 1) ~= sequence.length || size(data, 2) ~= 1
        print_debug('Value file does not have correct size');
        continue;
    end;

    sequence.values.names{end+1} = file.name(1:end-6);
    valuesdata = cat(2, valuesdata, data);

end;

sequence.values.data = valuesdata;

properties_filename = fullfile(sequence.directory, 'properties.txt');

if exist(properties_filename, 'file')
    sequence.properties = readstruct(properties_filename);
else
    sequence.properties = struct();
end;



