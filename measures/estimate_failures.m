function [failures] = estimate_failures(trajectory, sequence)

failures = sum(cellfun(@(x) numel(x) == 1 && x == 2, trajectory, 'UniformOutput', true));


