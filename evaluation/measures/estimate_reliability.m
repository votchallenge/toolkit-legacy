function [reliability] = estimate_reliability(trajectory, sequence, varargin)

skipping = 1;

args = varargin;
for j=1:2:length(args)
    switch varargin{j}
        case 'skipping', skipping = max(1, args{j+1});
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

reliability = sum(trajectory(:, 4) == -2) / (sequence.length / skipping);

