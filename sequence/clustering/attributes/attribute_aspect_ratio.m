function [mean_val, var_val, frames] = attribute_aspect_ratio(sequence)

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
