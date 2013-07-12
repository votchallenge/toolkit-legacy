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


