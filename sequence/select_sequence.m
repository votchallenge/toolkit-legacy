function [selected_sequence] = select_sequence(sequences)
% select_sequence Select sequence from a list interactively 
%
% The function provides an interactive interface for selecting a sequence from
% a given array of sequence descriptor structures.
%
% Input:
% - sequences (cell or structure): Array of sequence structures.
%
% Output:
% - selected_sequence (integer): An integer of a selected sequence in the array or an empty matrix.
%


print_text('Choose a sequence:');
print_indent(1);

for i = 1:length(sequences)
    print_text('%d - "%s"', i, sequences{i}.name);
end;

print_indent(-1);

option = input('Selected sequence: ', 's');

selected_sequence = int32(str2double(option));

if isempty(selected_sequence) || selected_sequence < 1 || selected_sequence > length(sequences)
    selected_sequence = [];
end;
