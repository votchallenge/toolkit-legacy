function [overlap] = calculate_overlap(T1, T2)
% CALCULATE_OVERLAP  Calculates per-frame overlap for two bounding-box trajectories.
%   OVERLAP = CALCULATE_OVERLAP(T1, T2) calculates overlap between trajectories
%       T1 and T2, where T1 and T2 are matrices of size N1 x 4 and N2 x 4, where
%       the corresponding columns for each matrix describe the upper left and top
%       coordinate as well as width and height of the bounding box. The resulting
%       vector OVERLAP is of size min(N1, N2) x 1.

len = min(size(T1, 1), size(T2, 1));
T1 = T1(1:len, :);
T2 = T2(1:len, :);

hrzInt = min(T1(:, 1) + T1(:, 3), T2(:, 1) + T2(:, 3)) - max(T1(:, 1), T2(:, 1));
hrzInt = max(0,hrzInt);
vrtInt = min(T1(:, 2) + T1(:, 4), T2(:, 2) + T2(:, 4)) - max(T1(:, 2), T2(:, 2));
vrtInt = max(0,vrtInt);
intersection = hrzInt .* vrtInt; 

union = (T1(:, 3) .* T1(:, 4)) + (T2(:, 3) .* T2(:, 4)) - intersection;

overlap = intersection ./ union;

overlap(any(isnan(T1),2) | any(isnan(T2),2)) = NaN;
