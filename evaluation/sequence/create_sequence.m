function [sequence] = create_sequence(name, directory)

groundtruth_file = fullfile(directory, 'groundtruth.txt');

groundtruth = double(csvread(groundtruth_file));

sequence = struct('name', name, 'directory', directory, ...
         'mask', '%08d.jpg', 'groundtruth', groundtruth, 'length', 0);

while true
    if isempty(get_image(sequence, sequence.length + 1))
        break;
    end;
    sequence.length = sequence.length + 1;
end;

sequence.length = min(sequence.length, size(groundtruth, 1));
