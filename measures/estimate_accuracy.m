function [accuracy, frames] = estimate_accuracy(trajectory, sequence, varargin)

burnin = 0;

for j=1:2:length(varargin)
    switch varargin{j}
        case 'burnin', burnin = max(0, varargin{j+1});
        otherwise, error(['unrecognized argument ' varargin{j}]);
    end
end

if burnin > 0
    
    mask = cellfun(@(r) numel(r) == 1 && r == 1, trajectory, 'UniformOutput', true);

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
