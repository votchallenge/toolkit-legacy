function [mean_val, var_val, frames] = attribute_aspect_ratio(sequence)
% attribute_aspect_ratio Computes the aspect ratio change attribute for the object in the given seqeunce
%
% Aspect ratio change is defined as the average of per-frame aspect ratio changes. 
% The aspect ratio change at frame `t` is calculated as the ratio of the bounding box width 
% and height in frame `t` divided by the ratio of the bounding box width and height in the first frame.
%
% Input:
% - sequence (struct): An array of sequence structures.
%
% Output:
% - mean_val : mean value of aspect ratio changes for the sequence
% - val_val  : variance of aspect ratio changes for the sequence
% - frames   : aspect ratio change for each frame

frames = zeros(sequence.length, 1);

region = region_convert(get_region(sequence, 1), 'rectangle');
defaultRatio = region(3)/region(4);
frames(1) = 0;  % log(1)

for i = 2:sequence.length
    region = region_convert(get_region(sequence, i), 'rectangle');
    if isnan(region(1))
        frames(i) = NaN;
    else
        frames(i) = log((region(3)/region(4))/defaultRatio);
    end
end;
framesID = find(~isnan(frames));
mean_val = mean(abs(frames(framesID(2:end))));
var_val = var(frames(framesID(2:end)));
