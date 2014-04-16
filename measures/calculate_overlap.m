function [overlap, only1, only2] = calculate_overlap(T1, T2)
% CALCULATE_OVERLAP  Calculates per-frame overlap for two bounding-box trajectories.
%   OVERLAP = CALCULATE_OVERLAP(T1, T2) calculates overlap between trajectories
%       T1 and T2, where T1 and T2 are matrices of size N1 x 4 and N2 x 4, where
%       the corresponding columns for each matrix describe the upper left and top
%       coordinate as well as width and height of the bounding box. The resulting
%       vector OVERLAP is of size min(N1, N2) x 1.

len = min(size(T1, 1), size(T2, 1));
T1 = T1(1:len, :);
T2 = T2(1:len, :);

if (~iscell(T1)) 
    T1 = num2cell(T1, 2); 
end 

if (~iscell(T2)) 
    T2 = num2cell(T2, 2); 
end 

results = cell2mat(cellfun(@(r1, r2) region_overlap(r1, r2), T1, T2, 'UniformOutput', false));

overlap = results(:, 1);
only1 = results(:, 2);
only2 = results(:, 3);
    
