function [state, location] = tracker_ncc_update(state, I, varargin)

gray = double(rgb2gray(I)) ; 

[height, width] = size(gray);

x1 = max(1, round(state.position(1) - state.window / 2));
y1 = max(1, round(state.position(2) - state.window / 2));
x2 = min(width, round(state.position(1) + state.window / 2));
y2 = min(height, round(state.position(2) + state.window / 2));

region = gray(y1:y2, x1:x2);

if any(size(region) < size(state.template))
    location = [state.position - state.size / 2, state.size];
    return;
end;

C = normxcorr2(state.template, region);

[~, imax] = max(C(:));
[my, mx] = ind2sub(size(C),imax(1));

position = [x1 + mx - 1 - state.size(1) / 2, y1 + my - 1 - state.size(2) / 2];

state.position = position;
location = [position - state.size / 2, state.size];

 
