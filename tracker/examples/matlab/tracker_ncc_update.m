function [state, location] = tracker_ncc_update(state, I, varargin)

gray = double(rgb2gray(I)) ; 

[height, width] = size(gray);

x1 = max(0, round(state.position(1) - state.window / 2));
y1 = max(0, round(state.position(2) - state.window / 2));
x2 = min(width-1, round(state.position(1) + state.window / 2));
y2 = min(height-1, round(state.position(2) + state.window / 2));

region = gray((y1:y2)+1, (x1:x2)+1);

if any(size(region) < size(state.template))
    location = [state.position - state.size / 2, state.size];
    return;
end;

C = normxcorr2(state.template, region);

% We are only using valid part of the response (where full template is used)
pad = size(state.template) - 1;
center = size(region) - pad - 1;
C = C([false(1,pad(1)) true(1,center(1))], [false(1,pad(2)) true(1,center(2))]);

x1 = x1 + pad(2);
y1 = y1 + pad(1);
[~, imax] = max(C(:));
[my, mx] = ind2sub(size(C),imax(1));

position = [x1 + mx - state.size(1) / 2, y1 + my - state.size(2) / 2];

state.position = position;
location = [position - state.size / 2, state.size];

 
