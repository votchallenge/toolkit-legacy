function [indices] = sequence_query_tag(sequence, tag, subset)
% sequence_query_tag Find tag occurences in sequence
%
% The function returns indices of all frames that contain the specified tag.
%
% Input:
% - sequence (structure): A valid sequence structure.
% - tag (string): Name of the tag.
% - subset (vector): A set of frame numbers or a binary mask to be used
% when looking for a tag. Frame indices will be returned relative to that
% subset of frames.
%
% Output:
% - indices (integer): A vector of indices of frames that contain the given tag.

if nargin < 3
   subset = true(sequence.length, 1);
end

if strcmp(tag, 'all')
    if nargin < 3
        indices = 1:sequence.length;
    else
        indices = 1:numel(subset);
    end;
    return;
end;

if strcmp(tag, 'empty')
    indices = find(all(~sequence.tags.data, 2));
    return;
end;

tag_index = find(strcmp(sequence.tags.names, tag), 1);

if isempty(tag_index)
    indices = [];
else
    indices = find(sequence.tags.data(subset, tag_index));
end;

