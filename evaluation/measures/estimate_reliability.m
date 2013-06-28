function [reliability] = estimate_reliability(trajectory, sequence)

reliability = sum(any(trajectory(:, 3:4) < 0,2));

