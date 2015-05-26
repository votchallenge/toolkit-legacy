function [count, failures] = estimate_failures(trajectory, sequence)

failures = find(cellfun(@(x) numel(x) == 1 && x == 2, trajectory, 'UniformOutput', true));

count = numel(failures);

