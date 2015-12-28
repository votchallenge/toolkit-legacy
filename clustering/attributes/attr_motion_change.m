function [mean_val, var_val, frames] = attr_motion_change(sequence)

motion = zeros(sequence.length, 2);

for i = 1:sequence.length
    
   % image = rgb2gray(imread(get_image(sequence, i)));
    
    region = get_aa_region(sequence, i);
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

