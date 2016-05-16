function [mean_val, var_val, frames] = attribute_color_change(sequence)
% attribute_color_change Computes the color change attribute of the object in the given seqeunce
%
% Object color change is defined as the change of the average hue value inside the bounding box.
%
% Input:
% - sequence (struct): An array of sequence structures.
%
% Output:
% - mean_val : mean value of the color change of the object for the sequence
% - val_val  : variance of the color change of the object for the sequence
% - frames   : the color change of the object for each frame

frames = zeros(sequence.length, 1);

image = rgb2hsv(imread(get_image(sequence, 1)));
image = image(:,:,1);
patch = cut_patch(image, region_convert(get_region(sequence, 1), 'rectangle'));
defHue = mean(double(patch(:)));
frames(1) = 0;

for i = 2:sequence.length
    image = rgb2hsv(imread(get_image(sequence, i)));
    image = image(:,:,1);    
    patch = cut_patch(image, region_convert(get_region(sequence, i), 'rectangle'));
    bb = region_convert(get_region(sequence, i), 'rectangle');
    if isnan(bb(1))
        frames(i) = NaN;
    else
        frames(i) = mean(double(patch(:))) - defHue;
    end
    
end;
framesID = find(~isnan(frames));
mean_val = mean(abs(frames(framesID(2:end))));
var_val = var(frames(framesID(2:end)));