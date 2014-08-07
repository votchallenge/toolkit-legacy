function [accuracy, frames] = estimate_accuracy(trajectory, sequence, varargin)

burnin = 0;

args = varargin;
for j=1:2:length(args)
    switch varargin{j}
        case 'burnin', burnin = max(0, args{j+1});
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

if burnin > 0
    
    stack = get_global_variable('stack', 'vot2014');
    
    if strcmp('vot2013', stack)    
        mask = cellfun(@(r) numel(r) == 1 || r(4) == -1, trajectory, 'UniformOutput', true);    
    else
        mask = cellfun(@(r) numel(r) == 1 && r == 1, trajectory, 'UniformOutput', true);
    end

    if is_octave()
        se = logical([zeros(burnin - 1, 1); ones(burnin, 1)]);
    else
        se = strel('arbitrary', [zeros(burnin - 1, 1); ones(burnin, 1)]);
    end;
    
    % ignore the next 'burnin' frames
    mask = imdilate(mask, se);

else    
    
    mask = false(size(trajectory, 1), 1);
    
end;

trajectory(mask) = {0};

if isstruct(sequence)
    frames = calculate_overlap(trajectory, get_region(sequence, 1:sequence.length));
else
    frames = calculate_overlap(trajectory, sequence);
end;

overlap = frames(~isnan(frames)); % filter-out illegal values

% Handle cases, where no overlap is available
if isempty(overlap)
    accuracy = 0;
else
    accuracy = mean(overlap);
end;
