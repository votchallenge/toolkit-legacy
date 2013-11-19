function [labels] = get_labels(sequence, index)

if (sequence.length < index || index < 1)
    labels = {};
else
    labels = sequence.labels.names(logical(sequence.labels.data(index, :)));
end;
 

