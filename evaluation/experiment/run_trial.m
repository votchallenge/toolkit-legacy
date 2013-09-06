function [trajectory, time] = run_trial(tracker, sequence, context)
% RUN_TRIAL  A wrapper around run_tracker that handles reinicialization
% when the tracker fails.
%
%   [TRAJECTORY, TIME] = RUN_TRIAL(TRACKER, SEQUENCE, CONTEXT)
%              Runs the tracker on a sequence. The resulting trajectory is
%              a composite of all correctly tracked fragments. Where
%              reinitialization occured, the frame is marked using a
%              special bounding box (0, 0, -1, -1).
%
%   See also RUN_TRACKER.

global track_properties;

start = 1;

total_time = 0;
total_frames = 0;

trajectory = zeros(sequence.length, 4);

trajectory(:, 1:3) = NaN;

while start < sequence.length

    [Tr, Tm] = tracker.run(tracker, sequence, start, context);

    if isempty(Tr)
        trajectory = [];
        time = NaN;
        return;
    end;

    total_time = total_time + Tm * size(Tr, 1);
    total_frames = total_frames + size(Tr, 1);

    overlap = calculate_overlap(Tr, get_region(sequence, start:sequence.length));

    failures = find(overlap' < 0.0000001 | ~isfinite(overlap'));
    failures = failures(failures > 1);

    trajectory(start, 4) = -1;
        
    if ~isempty(failures)

        first_failure = failures(1) + start - 1;
        
        trajectory(start + 1:min(first_failure, size(Tr, 1) + start - 1), :) = ...
            Tr(2:min(first_failure - start + 1, size(Tr, 1)), :);

        trajectory(first_failure, :) = [NaN, NaN, NaN, -2];
        start = first_failure + track_properties.skipping;
        print_debug(['INFO: Detected failure at frame ', num2str(first_failure), '. Reinitializing.']);

    else
        
        if size(Tr, 1) > 1
            trajectory(start + 1:min(sequence.length, size(Tr, 1) + start - 1), :) = ...
                Tr(2:min(sequence.length - start + 1, size(Tr, 1)), :);
        end;
        
        start = sequence.length;
    end;

    drawnow;
    
end;

time = total_time / total_frames;
