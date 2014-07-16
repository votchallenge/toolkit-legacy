function [value] = get_frame_value(sequence, key, index)

value_index = find(strcmp(sequence.values.names, key), 1);

if isempty(value_index)
    value = [];
	return;
end;

if nargin == 2
    
    region = sequence.values.data(value_index, :);
    
else

	region = sequence.values.data(value_index, index);

end;


