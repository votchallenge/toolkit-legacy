function [mean_val, var_val, frames] = attr_color_change(sequence)

frames = zeros(sequence.length, 1);

image = rgb2hsv(imread(get_image(sequence, 1)));
image = image(:,:,1);
patch = cut_patch(image, get_aa_region(sequence, 1));
defHue = mean(double(patch(:)));
frames(1) = 0;

for i = 2:sequence.length
    image = rgb2hsv(imread(get_image(sequence, i)));
    image = image(:,:,1);    
    patch = cut_patch(image, get_aa_region(sequence, i));
    bb = get_aa_region(sequence, i);
    if isnan(bb(1))
        frames(i) = NaN;
    else
        frames(i) = mean(double(patch(:))) - defHue;
    end
    
end;
framesID = find(~isnan(frames));
mean_val = mean(abs(frames(framesID(2:end))));
var_val = var(frames(framesID(2:end)));