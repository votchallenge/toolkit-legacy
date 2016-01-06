function [mean_val, var_val, frames] = attribute_illumination_change(sequence)
% attribute_illumination_change Computes the illumination change attribute of the object in the given seqeunce
%
% Illumination change is defined as the average of the absolute differences 
% between the object intensity in the first and remaining frames.
%
% Input:
% - sequence (struct): An array of sequence structures.
%
% Output:
% - mean_val : mean value of the illumination change of the object for the sequence
% - val_val  : variance of the illumination change of the object for the sequence
% - frames   : the illumination change of the object for each frame

frames = zeros(sequence.length, 1);

image = rgb2gray(imread(get_image(sequence, 1)));
patch = cut_patch(image, region_convert(get_region(sequence, 1), 'rectangle'));
defIntensity = mean(double(patch(:)) ./ 255);
frames(1) = 0;

for i = 2:sequence.length
    
    image = rgb2gray(imread(get_image(sequence, i)));
    patch = cut_patch(image, region_convert(get_region(sequence, i), 'rectangle'));
    bb = region_convert(get_region(sequence, i), 'rectangle');
    if isnan(bb(1))
        frames(i) = NaN;
    else
        frames(i) = mean(double(patch(:)) ./ 255) - defIntensity;
    end    
end;

framesID = find(~isnan(frames));
mean_val = mean(abs(frames(framesID(2:end))));
var_val = var(frames(framesID(2:end)));
