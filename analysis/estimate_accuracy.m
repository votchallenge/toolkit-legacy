function [accuracy, frames] = estimate_accuracy(trajectory, sequence, varargin)
% estimate_accuracy Calculate accuracy score
%
% Calculate accuracy score as average overlap over the entire sequence.
%
% Input:
% - trajectory (cell): A trajectory as a cell array of regions.
% - sequence (cell or structure): Can be another trajectory or a valid sequence descriptor.
% - varargin[Burnin] (integer): Number of frames that have to be ignored after the failure.
% - varargin[IgnoreUnknown] (boolean): Ignore frames where the overlap is
% unknown.
% - varargin[BindWithin] (boolean or vector): Bind the overlap calculation to the region
% within the image. If the sequence variable is a sequence structure then a boolean value
% is sufficient to establishe bounding region. Otherwise a bounding region has to be specified
% manually.
%
% Output:
% - accuracy (double): Average overlap.
% - frames (double vector): Per-frame overlaps.
%

ignore_unknown = true;
burnin = 0;
bind_within = get_global_variable('bounded_overlap', true);

for j=1:2:length(varargin)
    switch lower(varargin{j})
        case 'burnin', burnin = max(0, varargin{j+1});
        case 'ignoreunknown', ignore_unknown = varargin{j+1};
        case 'bindwithin', bind_within = varargin{j+1};
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

if ~ignore_unknown
    unknown = cellfun(@(r) numel(r) == 1 && r == 0, trajectory, 'UniformOutput', true);
end;

trajectory(mask) = {0};

if islogical(bind_within)
    if bind_within && isstruct(sequence)
        bounds = [sequence.width, sequence.height] - 1;
    else
        bounds = [];
    end;
else
    bounds = bind_within;
end;

if isstruct(sequence)
    frames = calculate_overlap(trajectory, get_region(sequence, 1:sequence.length), bounds);
else
    frames = calculate_overlap(trajectory, sequence, bounds);
end;

if ~ignore_unknown
    frames(unknown) = 0;
end;

overlap = frames(~isnan(frames)); % filter-out illegal values

% Handle cases, where no overlap is available
if isempty(overlap)
    accuracy = 0;
else
    accuracy = mean(overlap);
end;
