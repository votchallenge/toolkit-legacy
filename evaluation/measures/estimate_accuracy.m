function [accuracy] = estimate_accuracy(trajectory, sequence, varargin)

burnout = 0;

args = varargin;
for j=1:2:length(args)
    switch varargin{j}
        case 'burnout', burnout = max(0, args{j+1});
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

if burnout > 0
    
    mask = trajectory(:, 4) == -1; % determine initialization frames
    
    % ignore the next 'burnout' frames
    mask = imdilate(mask, strel('arbitrary', ...
        [zeros(burnout - 1, 1); ones(burnout, 1)]));

    trajectory(mask, 4) = 0;
    
end;

trajectory(trajectory(:, 4) <= 0, :) = NaN; % do not estimate overlap where the tracker was initialized

overlap = calculate_overlap(trajectory, get_region(sequence, 1:sequence.length));

overlap = overlap(~isnan(overlap)); % filter-out illegal values

accuracy = mean(overlap);

