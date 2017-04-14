function [tags] = sequence_get_tags(sequence, index)
% sequence_get_tags Returns all tags for a given frame
%
% Input:
% - sequence (structure): A valid sequence structure.
% - index (integer): A index of a frame.
%
% Output:
% - tags (cell): A cell array of strings. Names of tags for the given frame.

if (sequence.length < index || index < 1)
    tags = {};
else
    tags = sequence.tags.names(logical(sequence.tags.data(index, :)));
end;


