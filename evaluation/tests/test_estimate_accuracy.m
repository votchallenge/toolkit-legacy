
groundtruth = [linspace(0, 100, 50)', linspace(0, 100, 50)', repmat(10, 50,2)];

sequence = create_dummy_sequence('test', groundtruth);

acc1 = estimate_accuracy(groundtruth, sequence);

groundtruth(10, :) = [NaN, NaN, NaN, -1];

groundtruth(11:14, 1) = 0;

acc2 = estimate_accuracy(groundtruth, sequence);

acc3 = estimate_accuracy(groundtruth, sequence, 'burnin', 5);