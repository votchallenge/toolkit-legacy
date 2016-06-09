function [overlap, only1, only2] = calculate_overlap(T1, T2, bounds)
% calculate_overlap  Calculates overlap for two trajectories
%
% The function calculates per-frame overlap between two trajectories. Besides the
% region overlap the function also returns cointainment of the second trajectory in the
% first and containment of the first trajectory in the second.
%
% If the trajectories are not of equal length, then the overlaps are calculated up
% to the end of the shorter one.
%
% Input:
% - T1 (cell): The first trajectory.
% - T2 (cell): The second trajectory.
% - bounds (vector): An optional bounds of valid region where the overlap is calculated.
%
% Output:
% - overlap: A vector of per-frame overlaps.
% - only1: A vector of per-frame containment of the second trajectory in the first.
% - only2: A vector of per-frame containment of the first trajectory in the second.

len = min(size(T1, 1), size(T2, 1));
T1 = T1(1:len, :);
T2 = T2(1:len, :);

if (~iscell(T1)) 
    T1 = num2cell(T1, 2); 
end 

if (~iscell(T2)) 
    T2 = num2cell(T2, 2); 
end 

if nargin < 3
    bounds = [];
end

if get_global_variable('legacy_rasterization', true)
    mode = 'legacy';
else
    mode = 'default';
end;

results = region_overlap(T1, T2, bounds, mode);

%results = cell2mat(cellfun(@(r1, r2) region_overlap(r1, r2), T1, T2, 'UniformOutput', false));

overlap = results(:, 1);
only1 = results(:, 2);
only2 = results(:, 3);
    
