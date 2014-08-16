function reversed_sequence = sequence_reverse(sequence)

	reversed_sequence = sequence;
    reversed_sequence.groundtruth = sequence.groundtruth(end:-1:1);
    reversed_sequence.indices = sequence.indices(end:-1:1);
    reversed_sequence.images = sequence.images(end:-1:1);
    reversed_sequence.labels.data = sequence.labels.data(end:-1:1, :);

end
