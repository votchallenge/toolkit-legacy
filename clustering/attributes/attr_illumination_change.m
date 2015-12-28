function [mean_val, var_val, frames] = attr_illumination_change(sequence)

frames = zeros(sequence.length, 1);

image = rgb2gray(imread(get_image(sequence, 1)));
patch = cut_patch(image, get_aa_region(sequence, 1));
defIntensity = mean(double(patch(:)) ./ 255);
frames(1) = 0;

for i = 2:sequence.length
    
    image = rgb2gray(imread(get_image(sequence, i)));
    patch = cut_patch(image, get_aa_region(sequence, i));
    bb = get_aa_region(sequence, i);
    if isnan(bb(1))
        frames(i) = NaN;
    else
        frames(i) = mean(double(patch(:)) ./ 255) - defIntensity;
    end    
end;

framesID = find(~isnan(frames));
mean_val = mean(abs(frames(framesID(2:end))));
var_val = var(frames(framesID(2:end)));
