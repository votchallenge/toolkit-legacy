function [fragments, fragment_offset] = sequence_fragment(sequence, fragment_length)
% sequence_fragment Returns an array of subsequences
%
% This function returns a cell array of sequence objects that are fragments of the source sequence.
%
% Input:
% - sequence (structure): A valid sequence structure.
% - fragment_length (integer): The length of a single fragment.
%
% Output:
% - fragments (cell): A cell array of sequence descriptors.
% - fragment_offset(vector): A vector of offsets in the original sequence.

fragment_offset = [1:fragment_length:sequence.length, sequence.length+1];

fragments = cell(numel(fragment_offset)-1, 1);

for f = 1:numel(fragment_offset)-1
    indices = fragment_offset(f):fragment_offset(f+1)-1;
    fragments{f} = sequence;
    
    fragments{f}.groundtruth = sequence.groundtruth(indices, :);
    fragments{f}.indices = sequence.indices(indices);
    fragments{f}.labels.names = sequence.labels.names;
    fragments{f}.labels.data = sequence.labels.data(indices, :);
    fragments{f}.values.names = sequence.values.names;
    fragments{f}.values.data = sequence.values.data(indices, :);
    fragments{f}.images = sequence.images(indices);
    fragments{f}.length = length(indices);
    
end;

fragment_offset = fragment_offset(1:end-1);






