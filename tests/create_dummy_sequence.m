function [sequence] = create_dummy_sequence(name, groundtruth)

directory = '';

sequence = struct('name', name, 'directory', directory, ...
        'mask', '%08d.jpg', 'groundtruth', groundtruth, 'length', size(groundtruth, 1));

sequence.images = cell(sequence.length, 1);

sequence.initialization = @(sequence, index, context) get_region(sequence, index);

for i = 1:sequence.length
    
    sequence.images{i} = fullfile(directory, sprintf('%08d.jpg', i));
    
end;


