function [transformed_sequence] = sequence_pixelchange(sequence, operation)

global track_properties;

if ischar(operation)
    operation_name = operation;
    operation = str2func(operation_name);
else
    operation_name = func2str(operation);
end;

cache_directory = fullfile(track_properties.directory, 'cache', ...
    sprintf('pixelchange_%s', operation_name), sequence.name);

mkpath(cache_directory);

cache_groundtruth = fullfile(cache_directory, 'groundtruth.txt');

sequence_groundtruth = fullfile(sequence.directory, 'groundtruth.txt');

if file_newer_than(cache_groundtruth, sequence_groundtruth)
    transformed_sequence = create_sequence(sequence.name, cache_directory);
    transformed_sequence.labels.names = sequence.labels.names;
    transformed_sequence.labels.data = sequence.labels.data;
    return;
end;

print_debug('Generating cached sequence ''%s'' for operation ''%s''...', sequence.name, operation_name);

for i = 1:sequence.length
    
    original_image = imread(get_image(sequence, i));
    
    transformed_image = operation(original_image, i, sequence.length);
    
    if size(transformed_image, 3) == 1
        transformed_image = repmat(rgb2gray(transformed_image), [1 1 3]);
    end;
    
    if size(original_image, 1) ~= size(transformed_image, 1) || ...
            size(original_image, 2) ~= size(transformed_image, 2)
        error('The operation should return image of same width and height.');
    end;
    
    imwrite(transformed_image, fullfile(cache_directory, sprintf('%08d.jpg', i)));
    
end;

csvwrite(cache_groundtruth, sequence.groundtruth);

transformed_sequence = create_sequence(sequence.name, cache_directory);

transformed_sequence.labels.names = sequence.labels.names;
transformed_sequence.labels.data = sequence.labels.data;

