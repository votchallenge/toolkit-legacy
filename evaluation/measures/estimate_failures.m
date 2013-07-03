function [failures] = estimate_failures(trajectory, sequence)

failures = sum(trajectory(:, 4) == -2);

