function [trajectory, time] = run_trial(tracker, sequence)

start = 1;

total_time = 0;
total_frames = 0;

trajectory = zeros(sequence.length, 4);

while start < sequence.length

    [Tr, Tm] = run_tracker(tracker, sequence, start);

    if isempty(Tr)
        trajectory = [];
        time = NaN;
        return;
    end;

    total_time = total_time + Tm * size(Tr, 1);
    total_frames = total_frames + size(Tr, 1);

    overlap = calculate_overlap(Tr, get_region(sequence, start:sequence.length));

    failures = find(overlap' < 0.1);
    failures = failures(failures > 1);

    trajectory(start:min(sequence.length - 1, size(Tr, 1) + start), :) = ...
            Tr(1:min(sequence.length - start, size(Tr, 1)), :);

    if ~isempty(failures)
        first_failure = failures(1) + start - 1;
        trajectory(first_failure, :) = [0, 0, -1, -1];
        start = first_failure + 1;
        print_debug(['INFO: Detected failure at frame ', num2str(first_failure), '. Reinitializing.']);

    else
        start = sequence.length;
    end;

end;

time = total_time / total_frames;
