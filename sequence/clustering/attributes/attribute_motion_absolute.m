function [mean_val, var_val, frames] = attribute_motion_absolute(sequence)
% attribute_motion_absolute Computes the absolute motion attribute of the object in the given seqeunce
%
% Absolute motion is the median of the absolute motion difference of the 
% bounding box center points of the first frame and current one.
%
% Input:
% - sequence (struct): An array of sequence structures.
%
% Output:
% - mean_val : mean value of the absolute motion of the object for the sequence
% - val_val  : variance of the absolute motion of the object for the sequence
% - frames   : the absolute motion of the object for each frame

motion = zeros(sequence.length,1);
region = region_convert(get_region(sequence, 1), 'rectangle');
def_center = [region(1) + region(3)/2, region(2)+region(4)/2]./[region(3) region(4)];


for i = 1:sequence.length
    
   % image = rgb2gray(imread(get_image(sequence, i)));
    
    region = region_convert(get_region(sequence, i), 'rectangle');
    if isnan(region)
        motion(i) = NaN;
    else
        motion(i) = sqrt(sum(((def_center - [region(1) + region(3)/2, region(2)+region(4)/2]./[region(3) region(4)])).^2));
    end
    
end;
idx = ~isnan(motion);

mean_val = median(motion(idx));
var_val = var(motion(idx));
frames = motion;
