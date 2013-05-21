function [region] = track_get_region(sequence, index)

region = sequence.groundtruth(index, :);


