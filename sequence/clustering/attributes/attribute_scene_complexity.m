function [mean_val, var_val, frames] = attr_scene_complexity(sequence)

frames = zeros(sequence.length, 1);

image = rgb2gray(imread(get_image(sequence, 1)));
frames(1) = entropy(image);

for i = 2:sequence.length
    image = rgb2gray(imread(get_image(sequence, i)));
    frames(i) = entropy(image);
end;

mean_val = mean(frames(~isnan(frames)));
var_val = var(frames(~isnan(frames)));