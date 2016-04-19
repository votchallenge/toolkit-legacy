function [indices] = query_label(sequence, label, subset)
% query_label Find label in sequence
%
% The function returns indices of all frames that contain the specified label.
%
% Input:
% - sequence (structure): A valid sequence structure.
% - label (string): Name of the label.
% - subset (vector): A set of frame numbers or a binary mask to be used
% when looking for a label. Frame indices will be returned relative to that
% subset of frames.
%
% Output:
% - indices (integer): A vector of indices of frames that contain the given label.

if nargin < 3
   subset = true(sequence.length, 1); 
end

if strcmp(label, 'all')
    if nargin < 3
        indices = 1:sequence.length;
    else
        indices = 1:numel(subset);
    end;
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
    indices = find(sequence.labels.data(subset, label_index));
end;

