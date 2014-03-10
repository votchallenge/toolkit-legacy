function [styled_trackers] = set_trackers_visual_identity(trackers)

colors = repmat(hsv(7), ceil(length(trackers) / 7), 1);
symbol = repmat({'o', 'x', '*', 'v', 'd', '+', '<', 'p', '>'}, 1, ceil(length(trackers) / 9));
width = mod(1:length(trackers), 5) / 5 + 1.5;

styled_trackers = cell(length(trackers), 1);

for i = 1:length(trackers)
    styled_trackers{i} = trackers{i};
    styled_trackers{i}.style.color = colors(i, :);
    styled_trackers{i}.style.symbol = symbol{i};
    styled_trackers{i}.style.width = width(i);
    if isfield(trackers{i}, 'label')
        styled_trackers{i}.label = trackers{i}.label;
    else
        styled_trackers{i}.label = trackers{i}.identifier;
    end;
end;