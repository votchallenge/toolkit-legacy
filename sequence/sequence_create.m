function [sequence] = sequence_create(sequence_path, varargin)
% sequence_create Create a new sequence descriptor
%
% Create a new sequence structure by loading the information from the directory.
%
% Input:
% - sequence_path: Path to the sequence directory or to the sequence metadata file.
% - varargin[Name]: Name of the sequence. By default the name of the directory is taken as the name of the sequence.
% - varargin[Dummy]: Create the sequence structure without checking if all the images exist.
% - varargin[Start]: The number of the first frame in the sequence (1 by default).
%
% Output:
% - sequence: A new sequence structure.

start = 1;
dummy = false;
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

channel_directory = directory;

if ~isfield(metadata, 'channels') || ~isfield(metadata.channels, default_channel)
	if all(size(dir([directory, '/*.jpg'])))
		mask = '%08d.jpg';
	elseif all(size(dir([directory, '/*.png'])))
		mask = '%08d.png';
	end;
else
    [sdir, sfile, sext] = fileparts(metadata.channels.(default_channel));
    
    channel_directory = fullfile(directory, sdir);
    
    if isempty(sfile)
        mask = '%08d.jpg';
    else
        mask = [sfile, sext];
    end
    
end;

[~, name] = fileparts(directory);

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'name'
            name = varargin{i+1};
        case 'dummy'
            dummy = varargin{i+1};
        case 'start'
            start = varargin{i+1};
        otherwise
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end

if isempty(mask)
    error('Unkown file ending for sequence frames');
end;

sequence = struct('name', name, 'directory', directory, ...
        'mask', mask, 'length', 0, ...
        'file', 'groundtruth.txt', 'images_directory', channel_directory);

sequence.groundtruth = read_trajectory(fullfile(sequence.directory, sequence.file));

sequence.images = cell(numel(sequence.groundtruth), 1);

sequence.initialize = @(sequence, index, context) get_region(sequence, index);

while true
    image_name = sprintf(mask, sequence.length + start);

    if ~exist(fullfile(channel_directory, image_name), 'file')
        if dummy && sequence.length > 0 && sequence.length <= numel(sequence.groundtruth)
            sequence.images{sequence.length + 1} = sequence.images{1};
        else
            break;
        end;
    else
        sequence.images{sequence.length + 1} = image_name;
    end;

	sequence.length = sequence.length + 1;
end;

sequence.indices = 1:sequence.length;

sequence.length = min(sequence.length, numel(sequence.groundtruth));

if sequence.length < 1
    error('Empty sequence: %s', name);
end;

imdata = imread(get_image(sequence, 1));

[height, width, channels] = size(imdata);

sequence.grayscale = channels == 1 || isequal(imdata(:, :, 1), ...
		imdata(:, :, 2), imdata(:, :, 3));

sequence.width = width;
sequence.height = height;
sequence.channels = channels;

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

    sequence.tags.names{end+1} = file.name(1:end-6);
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



