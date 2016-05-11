function [mean_val, var_val, frames] = attribute_scene_complexity(sequence)
% attribute_scene_complexity Computes the scene complexity attribute in the given seqeunce
%
% Scene complexity represents the level of randomness (entropy) in the 
% frames and it was calculated as $e = \sum_{i = 0}^{255}b_i\log b_i$, 
% where $b_i$ is the number of pixels with value equal to $i$.
%
% Input:
% - sequence (struct): An array of sequence structures.
%
% Output:
% - mean_val : mean value of scene complexity for the sequence
% - val_val  : variance of scene complexity for the sequence
% - frames   : scene complexity for each frame

frames = zeros(sequence.length, 1);

image = rgb2gray(imread(get_image(sequence, 1)));
frames(1) = entropy(image);

for i = 2:sequence.length
    image = rgb2gray(imread(get_image(sequence, i)));
    frames(i) = entropy(image);
end;

mean_val = mean(frames(~isnan(frames)));
var_val = var(frames(~isnan(frames)));