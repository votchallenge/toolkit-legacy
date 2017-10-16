function [cut_sequence] = sequence_cut(sequence, from, to)
% sequence_cut Returns a sequence that is a sub-interval of the source sequence
%
% This sequence converter returns a sub-sequence from the source sequence.
%
% Input:
% - sequence (structure): A valid sequence structure.
% - ratio (double): Resize ratio (between 10 and 0.1)
%
% Output:
% - cut_sequence (structure): A sequence descriptor of a converted sequence.

from = max(0, min(from, sequence.length));
to = max(from, min(to, sequence.length));

cut_sequence = sequence;

cut_sequence.groundtruth = cut_sequence.groundtruth(from:to);
cut_sequence.images = cut_sequence.images(from:to);
cut_sequence.indices = cut_sequence.indices(from:to);
cut_sequence.tags.data = sequence.tags.data(from:to, :);
cut_sequence.values.data = sequence.values.data(from:to, :);
cut_sequence.length = to - from + 1;
