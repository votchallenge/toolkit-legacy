function [indices] = query_label(sequence, label)

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

