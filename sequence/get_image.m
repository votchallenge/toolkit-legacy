function [image_path] = get_image(sequence, index)

if (sequence.length < index || index < 1)
    image_path = [];
else
    image_path = fullfile(sequence.directory, sequence.images{index});
end;
 

