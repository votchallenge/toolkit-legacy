function [index, sequence] = find_sequence(sequences, name)
% find_sequence Find a sequence by its name
%
% Find a sequence by its name in a cell array of sequence structures. Returns index of sequence and its structure.
% If a sequence is not found the function returns an empty matrix.
%
% Input:
% - sequences: Cell array of sequence structures.
% - name: A string containing sequence namer.
%
% Output:
% - index: Index of the sequence in the cell array or empty matrix if not found. 
% - sequence: The sequence structure.

index = find(cellfun(@(t) strcmp(t.name, name), sequences, 'UniformOutput', true), 1);

if isempty(index)
    sequence = [];
else
    sequence = sequences{index};
end;
