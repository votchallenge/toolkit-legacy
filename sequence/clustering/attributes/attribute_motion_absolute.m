function [mean_val, var_val, frames] = attr_motion_absolute(sequence)

motion = zeros(sequence.length,1);
region = get_aa_region(sequence, 1);
def_center = [region(1) + region(3)/2, region(2)+region(4)/2]./[region(3) region(4)];


for i = 1:sequence.length
    
   % image = rgb2gray(imread(get_image(sequence, i)));
    
    region = get_aa_region(sequence, i);
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
