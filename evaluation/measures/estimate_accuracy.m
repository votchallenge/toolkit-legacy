function [accuracy] = estimate_accuracy(trajectory, sequence)

trajectory(any(trajectory(:, 3:4) < 0), :) = NaN; % do not estimate overlap where the tracker was initialized

overlap = calculate_overlap(trajectory, get_region(sequence, 1:sequence.length));

overlap = overlap(~isnan(overlap)); % filter-out illegal values

accuracy = mean(overlap);

