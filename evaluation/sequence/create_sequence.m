function [sequence] = create_sequence(name, directory)

groundtruth_file = fullfile(directory, 'groundtruth.txt');

groundtruth = double(csvread(groundtruth_file));

mask = '%08d.jpg';

sequence = struct('name', name, 'directory', directory, ...
        'mask', '%08d.jpg', 'groundtruth', groundtruth, 'length', 0, ...
        'images', cell(0));

while true
    image_name = fsprintf(mask, sequence.length + 1);

    if ~exist(fullfile(sequence.directory, image_name, 'file'))
        break;
    end;

    sequence.images{end+1} = image_name;

    sequence.length = sequence.length + 1;
end;

sequence.length = min(sequence.length, size(groundtruth, 1));
