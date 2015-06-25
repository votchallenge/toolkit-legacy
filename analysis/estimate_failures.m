function [count, failures] = estimate_failures(trajectory, sequence)
% estimate_failures Computes number of failures score
%
% Scans the trajectory for instances of tracker failure and returns the number of failures.
%
% Input:
% - trajectory (cell): A trajectory as a cell array of regions.
% - sequence (cell): A valid sequence descriptor.
%
% Output:
% - count (integer): Number of failures
% - failures (integer vector): Indices of frames where the tracker failed
%

failures = find(cellfun(@(x) numel(x) == 1 && x == 2, trajectory, 'UniformOutput', true));

count = numel(failures);

