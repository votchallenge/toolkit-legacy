function [selected_sequence] = select_sequence(sequences)

print_text('Please choose a sequence:');
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