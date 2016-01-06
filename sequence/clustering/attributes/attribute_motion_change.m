function [mean_val, var_val, frames] = attribute_motion_change(sequence)
% attribute_motion_change Computes the object motion attribute of the object in the given seqeunce
%
% Object motion is the average of absolute differences between ground 
% truth center positions in consecutive frames.
%
% Input:
% - sequence (struct): An array of sequence structures.
%
% Output:
% - mean_val : mean value of the object motion of the object for the sequence
% - val_val  : variance of the object motion of the object for the sequence
% - frames   : the object motion of the object for each frame

motion = zeros(sequence.length, 2);

for i = 1:sequence.length
    
   % image = rgb2gray(imread(get_image(sequence, i)));
    
    region = region_convert(get_region(sequence, i), 'rectangle');
    if isnan(region)
        motion(i, :) = [NaN, NaN];
    else
        motion(i, :) = [region(1) + region(3)/2, region(2)+region(4)/2]./[region(3) region(4)];
    end
    
end;
%motion = diff(motion);
motion = conv2(motion', [1 0 0 0 0 0 0 0 0 0 -1], 'same')';
frames = sqrt(sum(motion .^ 2, 2));

tmp = frames(~isnan(frames));

mean_val = min([1 median(tmp(6:end-5))]);   %cuped at 1
var_val = var(tmp(6:end-5));

