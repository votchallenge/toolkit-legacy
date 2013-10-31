function [resized_sequence] = sequence_resize(sequence, ratio)

global track_properties;

ratio = min(10, max(0.1, ratio));

cache_directory = fullfile(track_properties.directory, 'cache', ...
    sprintf('resize_%.2f', ratio), sequence.name);

mkpath(cache_directory);

cache_groundtruth = fullfile(cache_directory, 'groundtruth.txt');

sequence_groundtruth = fullfile(sequence.directory, 'groundtruth.txt');

if file_newer_than(cache_groundtruth, sequence_groundtruth)
    resized_sequence = create_sequence(sequence.name, cache_directory);
    resized_sequence.labels.names = sequence.labels.names;
    resized_sequence.labels.data = sequence.labels.data;
    return;
end;

print_debug('Generating cached resized sequence ''%s'' for scaling factor %.2f...', sequence.name, ratio);

for i = 1:sequence.length
    
    color_image = imread(get_image(sequence, i));
    
    scaled_image = imresize(color_image, ratio);
    
    imwrite(scaled_image, fullfile(cache_directory, sprintf('%08d.jpg', i)));
    
end;

csvwrite(cache_groundtruth, sequence.groundtruth .* ratio);

resized_sequence = create_sequence(sequence.name, cache_directory);

resized_sequence.labels.names = sequence.labels.names;
resized_sequence.labels.data = sequence.labels.data;

