function [indices] = query_label(sequence, label)

label_index = min(find(strcmp(sequence.labels.names, label)));

if isempty(label_index)
    indices = [];
else
    indices = find(sequence.labels.data(:, label_index));
end;

