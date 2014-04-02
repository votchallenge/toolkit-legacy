function [region] = get_region(sequence, index)

if numel(index) == 1
    region = sequence.groundtruth{index};
else
    region = sequence.groundtruth(index);
end;


