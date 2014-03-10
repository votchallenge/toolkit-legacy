function [region] = get_region(sequence, index)

region = sequence.groundtruth(index, :);


