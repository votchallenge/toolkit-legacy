function [failures] = estimate_failures(trajectory, sequence)

stack = get_global_variable('stack', 'vot2014');

if strcmp('vot2013', stack)    
    failures = sum(cellfun(@(x) numel(x) == 1 || x(4) == -2, trajectory, 'UniformOutput', true));    
else
    failures = sum(cellfun(@(x) numel(x) == 1 && x == 2, trajectory, 'UniformOutput', true));
end



