function [resized_sequence] = sequence_resize(sequence, ratio)
% sequence_resize Returns resized sequence
%
% This sequence converter returns a sequence with resized frames and annotations.
%
% Cache notice: The results of this function are cached in the workspace cache directory.
%
% Input:
% - sequence (structure): A valid sequence structure.
% - ratio (double): Resize ratio (between 10 and 0.1)
%
% Output:
% - resized_sequence (structure): A sequence descriptor of a converted sequence.

ratio = min(10, max(0.1, ratio));

cache_directory = fullfile(get_global_variable('directory'), 'cache', ...
    sprintf('resize_%.2f', ratio), sequence.name);

mkpath(cache_directory);

cache_groundtruth = fullfile(cache_directory, 'groundtruth.txt');

sequence_groundtruth = fullfile(sequence.directory, 'groundtruth.txt');

if file_newer_than(cache_groundtruth, sequence_groundtruth)
    resized_sequence = create_sequence(cache_directory, 'name', sequence.name);
    resized_sequence.labels.names = sequence.labels.names;
    resized_sequence.labels.data = sequence.labels.data;
    resized_sequence.values.names = sequence.values.names;
    resized_sequence.values.data = sequence.values.data;
    return;
end;

print_debug('Generating cached resized sequence ''%s'' for scaling factor %.2f...', sequence.name, ratio);

for i = 1:sequence.length
    
    color_image = imread(get_image(sequence, i));
    
    scaled_image = imresize(color_image, ratio);
    
    imwrite(scaled_image, fullfile(cache_directory, sprintf('%08d.jpg', i)));
    
end;

function region = rescale_region(region)

    if numel(region) > 3
        region = region .* ratio;
    end;

end

write_trajectory(cache_groundtruth, cellfun(@(x) rescale_region(x), sequence.groundtruth, 'UniformOutput', false));

resized_sequence = create_sequence(cache_directory, 'name', sequence.name);

resized_sequence.labels.names = sequence.labels.names;
resized_sequence.labels.data = sequence.labels.data;
resized_sequence.values.names = sequence.values.names;
resized_sequence.values.data = sequence.values.data;

end
