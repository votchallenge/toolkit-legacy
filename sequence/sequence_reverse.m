function reversed_sequence = sequence_reverse(sequence)
% sequence_reverse Returns reverse sequence
%
% This sequence converter returns a sequence with all its frames reversed.
%
% Input:
% - sequence (structure): A valid sequence structure.
%
% Output:
% - reversed_sequence (structure): A sequence descriptor of a converted sequence.

reversed_sequence = sequence;
reversed_sequence.groundtruth = sequence.groundtruth(end:-1:1);
reversed_sequence.indices = sequence.indices(end:-1:1);
reversed_sequence.images = sequence.images(end:-1:1);
reversed_sequence.labels.data = sequence.labels.data(end:-1:1, :);
reversed_sequence.values.data = sequence.values.data(end:-1:1, :);

