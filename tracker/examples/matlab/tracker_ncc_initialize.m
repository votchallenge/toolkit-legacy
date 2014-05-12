function [state, location] = tracker_ncc_initialize(I, region, varargin)

gray = double(rgb2gray(I));

[height, width] = size(gray);

% If the provided region is a polygon ...
if numel(region) > 4
	x1 = min(region(1:2:end);
	x2 = max(region(1:2:end);
	y1 = min(region(2:2:end);
	y2 = max(region(2:2:end);

	region = [x1, y1, x2 - x1, y2 - y1];
end;

x1 = max(1, region(1));
y1 = max(1, region(2));
x2 = min(width, region(1) + region(3));
y2 = min(height, region(2) + region(4));
 
template = gray(y1:y2, x1:x2);

position = [x1 + x2, y1 + y2] / 2;

state = struct('template', template, 'position', position, ...
    'window', max([x2 - x1, y2 - y1]) * 2, 'size', [x2 - x1, y2 - y1] ) ;
    
location = [x1, y1, x2 - x1, y2 - y1];

 
