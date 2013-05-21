function [image_path] = track_get_image(sequence, index)

image_path = fullfile(sequence.directory, sprintf(sequence.mask, index));

if ~exist(image_path, 'file')
    image_path = [];
end;


