function [skipped_sequence] = sequence_skipping(sequence, skipping)

skipped_sequence = sequence;

indices = 1:skipping:sequence.length;

skipped_sequence.groundtruth = sequence.groundtruth(indices, :);

skipped_sequence.labels.names = sequence.labels.names;
skipped_sequence.labels.data = sequence.labels.data(indices, :);

skipped_sequence.images = sequence.images(indices);

skipped_sequence.length = length(indices);

