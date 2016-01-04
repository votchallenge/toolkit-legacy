function [mean_val, var_val, frames] = attribute_size_change(sequence)

frames = zeros(sequence.length, 1);

region = region_convert(get_region(sequence, 1), 'rectangle');
defaultArea = region(3)*region(4);
frames(1) = 0; % log(1)

for i = 2:sequence.length
    region = region_convert(get_region(sequence, i), 'rectangle');
    %frames(i) = 1-region(3)*region(4)/defaultArea;
    frames(i) = abs(log(sqrt(region(3)*region(4)/defaultArea)));
end;
framesID = find(~isnan(frames));
mean_val = quantile(frames(framesID(2:end)), 0.9) - quantile(frames(framesID(2:end)), 0.1);
%mean_val = mean(frames(framesID(2:end)));
var_val = var(frames(framesID(2:end)));
