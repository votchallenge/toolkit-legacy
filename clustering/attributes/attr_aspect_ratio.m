function [mean_val, var_val, frames] = attr_aspect_ratio(sequence)

frames = zeros(sequence.length, 1);

region = get_aa_region(sequence, 1);
defaultRatio = region(3)/region(4);
frames(1) = 0;  % log(1)

for i = 2:sequence.length
    region = get_aa_region(sequence, i);
    if isnan(region(1))
        frames(i) = NaN;
    else
        frames(i) = log((region(3)/region(4))/defaultRatio);
    end
end;
framesID = find(~isnan(frames));
mean_val = mean(abs(frames(framesID(2:end))));
var_val = var(frames(framesID(2:end)));