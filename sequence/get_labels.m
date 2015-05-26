function [labels] = get_labels(sequence, index)
% get_labels Returns labels for a given frame
%
% Input:
% - sequence (structure): A valid sequence structure.
% - index (integer): A index of a frame.
%
% Output:
% - labels (cell): A cell array of strings. Names of labels for the given frame.

if (sequence.length < index || index < 1)
    labels = {};
else
    labels = sequence.labels.names(logical(sequence.labels.data(index, :)));
end;
 

