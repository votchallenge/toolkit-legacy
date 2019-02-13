function [image_paths] = sequence_get_image(sequence, index, channels)
% sequence_image_path Returns image path for the given sequence
%
% Input:
% - sequence: A valid sequence structure.
% - index: A index of a frame.
% - channels: Which channels to retrieve.
%
% Output:
% - image_paths: An image parh for the requested frame or an empty matrix if the frame number is invalid.

if nargin < 3
    channels = sequence.default;
end

if isempty(channels) 
    channels = fieldnames(sequence.channels);
end

if ~iscell(channels)
    channels = {channels};
end;

if isfield(sequence, 'format')
    sequence_function = str2func(['sequence_get_image_', sequence.format]);
    image_paths = sequence_function(sequence, index, channels);
    return;
end

if any(sequence.length < index | index < 1)
    image_paths = [];
else

    image_paths = cell(numel(channels), numel(index));
    
    for i = 1:numel(channels)
        %image_paths(i, :) = cellfun(@(x) sprintf(sequence.channels.(channels{i}), x), num2cell(sequence.indices(index)), 'UniformOutput', false);
        image_paths(i, :) = cellfun(@(x) sprintf(strrep(sequence.channels.(channels{i}), '\', '\\'), x), ...
            num2cell(sequence.indices(index)), 'UniformOutput', false);
    end;
    if numel(image_paths) == 1
        image_paths = image_paths{1};
    end;
    
end;


