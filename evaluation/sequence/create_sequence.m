function [sequence] = create_sequence(name, directory)

groundtruth_file = fullfile(directory, 'groundtruth.txt');

groundtruth = double(csvread(groundtruth_file));

mask = '%08d.jpg';

sequence = struct('name', name, 'directory', directory, ...
        'mask', '%08d.jpg', 'groundtruth', groundtruth, 'length', 0);

sequence.images = cell(size(groundtruth, 1), 1);

sequence.initialize = @(sequence, index, context) get_region(sequence, index);

while true
    image_name = sprintf(mask, sequence.length + 1);

    if ~exist(fullfile(sequence.directory, image_name), 'file')
        break;
    end;

    sequence.images{sequence.length + 1} = image_name;

	sequence.length = sequence.length + 1;
end;

sequence.length = min(sequence.length, size(groundtruth, 1));

if sequence.length < 1
    error('Empty sequence: %s', name);
end;

[height, width, channels] = size(imread(get_image(sequence, 1)));

sequence.width = width;
sequence.height = height;
sequence.channels = channels;

labelnames = {};
labeldata = false(sequence.length, 0);

print_indent(1);

for file = dir(fullfile(directory, '*.label'))

    try
        data = csvread(fullfile(directory, file.name));
    catch 
        continue
    end;

    if size(data, 1) ~= sequence.length || size(data, 2) ~= 1
        continue;
    end;

    print_debug('Found label %s', file.name(1:end-6));

    labelnames{end+1} = file.name(1:end-6);
    labeldata = cat(2, labeldata, data > 0);

end;

print_indent(-1);

sequence.labels.names = labelnames;
sequence.labels.data = labeldata;

