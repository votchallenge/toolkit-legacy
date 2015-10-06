function [sequence] = create_sequence(directory, varargin)
% create_sequence Create a new sequence descriptor
%
% Create a new sequence structure by loading the information from the directory.
%
% Input:
% - directory: Path to the sequence directory.
% - varargin[Name]: Name of the sequence. By default the name of the directory is taken as the name of the sequence.
% - varargin[Mask]: File pattern for images. By default '%08d.jpg' is used.
% - varargin[Dummy]: Create the sequence structure without checking if all the images exist.
% - varargin[Start]: The number of the first frame in the sequence (1 by default).
%
% Output:
% - sequence: A new sequence structure.

start = 1;
dummy = false;

if all(size(dir([directory '/*.jpg'])))
    mask = '%08d.jpg';
elseif all(size(dir([directory '/*.png'])))
    mask = '%08d.png';
else
    error('Unkown file ending for sequence frames');
end;


[parent, name] = fileparts(directory);

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'name'
            name = varargin{i+1};
        case 'mask'
            mask = varargin{i+1};
        case 'dummy'
            dummy = varargin{i+1};
        case 'start'
            start = varargin{i+1};                
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

sequence = struct('name', name, 'directory', directory, ...
        'mask', mask, 'length', 0, ...
        'file', 'groundtruth.txt');

sequence.groundtruth = read_trajectory(fullfile(sequence.directory, sequence.file));

sequence.images = cell(numel(sequence.groundtruth), 1);

sequence.initialize = @(sequence, index, context) get_region(sequence, index);

while true
    image_name = sprintf(mask, sequence.length + start);

    if ~exist(fullfile(sequence.directory, image_name), 'file')
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

sequence.labels.names = {};
labeldata = false(sequence.length, 0);

for file = dir(fullfile(directory, '*.label'))'

    try
        data = csvread(fullfile(directory, file.name));
    catch e
        e.message
        continue
    end;

    if size(data, 1) > sequence.length || size(data, 2) ~= 1
        print_debug('Label file does not have correct size');
        continue;
    end;

    if size(data, 1) < sequence.length
        data(end+1:sequence.length) = 0;
    end;
    
    sequence.labels.names{end+1} = file.name(1:end-6);
    labeldata = cat(2, labeldata, data > 0);

end;

sequence.labels.data = labeldata;

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



