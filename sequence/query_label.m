function [indices] = query_label(sequence, label)
% query_label Find label in sequence
%
% The function returns indices of all frames that contain the specified label.
%
% Input:
% - sequence (structure): A valid sequence structure.
% - label (string): Name of the label.
%
% Output:
% - indices (integer): A vector of indices of frames that contain the given label.

if strcmp(label, 'all')
    indices = 1:sequence.length;
    return;
end;

if strcmp(label, 'empty')
    indices = find(all(~sequence.labels.data, 2));
    return;
end;

label_index = find(strcmp(sequence.labels.names, label), 1);

if isempty(label_index)
    indices = [];
else
    indices = find(sequence.labels.data(:, label_index));
end;

