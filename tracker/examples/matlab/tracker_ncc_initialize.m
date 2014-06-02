function [state, location] = tracker_ncc_initialize(I, region, varargin)

gray = double(rgb2gray(I));

[height, width] = size(gray);

% If the provided region is a polygon ...
if numel(region) > 4
	x1 = round(min(region(1:2:end)));
	x2 = round(max(region(1:2:end)));
	y1 = round(min(region(2:2:end)));
	y2 = round(max(region(2:2:end)));
	region = round([x1, y1, x2 - x1, y2 - y1]);
else
	region = round([round(region(1)), round(region(2)), ... 
		round(region(1) + region(3)) - round(region(1)), ...
		round(region(2) + region(4)) - round(region(2))]);
end;

x1 = max(0, region(1));
y1 = max(0, region(2));
x2 = min(width-1, region(1) + region(3) - 1);
y2 = min(height-1, region(2) + region(4) - 1);
 
template = gray((y1:y2)+1, (x1:x2)+1);

state = struct('template', template, 'size', [x2 - x1 + 1, y2 - y1 + 1]);
state.window = max(state.size) * 2;
state.position = [x1 + x2 + 1, y1 + y2 + 1] / 2;

state

location = [x1, y1, state.size];

