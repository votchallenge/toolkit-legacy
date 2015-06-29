function [value] = get_frame_value(sequence, key, index)
% get_frame_value Returns frame values for the given sequence
%
% Input:
% - sequence (structure): A valid sequence structure.
% - key (string): Key of a value.
% - index (integer, optional): A index of a frame or a vector of frames. If not present the entire sequence is assumed.
%
% Output:
% - value: A vector of values for corresponing frames.

value_index = find(strcmp(sequence.values.names, key), 1);

if isempty(value_index)
    value = [];
	return;
end;

if nargin == 2
    
    value = sequence.values.data(:, value_index);
    
else

	value = sequence.values.data(index, value_index);

end;


