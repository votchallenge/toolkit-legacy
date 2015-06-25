function [skipped_sequence] = sequence_skipping(sequence, skip, keep)
% sequence_skipping Returns sequence with skipped frames
%
% This sequence converter returns a sequence that omits a periodic pattern frames.
%
% Cache notice: The results of this function are cached in the workspace cache directory.
%
% Input:
% - sequence (structure): A valid sequence structure.
% - skip (integer): Number of frames to skip in a period.
% - keep (integer): Number of frames to keep in a period.
%
% Output:
% - skipped_sequence (structure): A sequence descriptor of a converted sequence.

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
skipped_sequence.values.names = sequence.values.names;
skipped_sequence.values.data = sequence.values.data(indices, :);

skipped_sequence.images = sequence.images(indices);

skipped_sequence.length = length(indices);

