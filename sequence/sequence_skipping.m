function [skipped_sequence] = sequence_skipping(sequence, skip, keep)

skip = min(10, max(1, skip));
keep = min(10, max(1, keep));

skipped_sequence = sequence;

indices = 1:sequence.length;

mask = mod(indices, skip + keep);
indices = indices(mask > 0 & mask < (keep + 1));

skipped_sequence.groundtruth = sequence.groundtruth(indices, :);
skipped_sequence.indices = sequence.indices(indices, :);
skipped_sequence.labels.names = sequence.labels.names;
skipped_sequence.labels.data = sequence.labels.data(indices, :);

skipped_sequence.images = sequence.images(indices);

skipped_sequence.length = length(indices);

