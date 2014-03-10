
initialize_defaults;

tracker = create_tracker('test', 'dir', tempdir);

groundtruth = [linspace(0, 100, 50)', linspace(0, 100, 50)', repmat(10, 50,2)];

sequence = create_dummy_sequence('test', groundtruth);

tracker.run = @(tracker, sequence, start, context) deal(get_region(sequence, start:sequence.length), 1);

[trajectory1, t1] = run_trial(tracker, sequence, struct('repetition', 1, 'repetitions', 1));

tracker.run = @(tracker, sequence, start, context) deal(repmat(get_region(sequence, start), sequence.length - start + 1, 1), 1);

[trajectory2, t2] = run_trial(tracker, sequence, struct('repetition', 1, 'repetitions', 1));