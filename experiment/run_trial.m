function [trajectory, time] = run_trial(tracker, sequence, context, varargin)
% RUN_TRIAL  A wrapper around run_tracker that handles reinicialization
% when the tracker fails.
%
%   [TRAJECTORY, TIME] = RUN_TRIAL(TRACKER, SEQUENCE, CONTEXT)
%              Runs the tracker on a sequence. The resulting trajectory is
%              a composite of all correctly tracked fragments. Where
%              reinitialization occured, the frame is marked using a
%              special notation.
%
%   See also RUN_TRACKER.

skip_labels = {};

skip_initialize = 1;

fail_overlap = -1; % disable failure detection by default

args = varargin;
for j=1:2:length(args)
    switch varargin{j}
        case 'skip_labels', skip_labels = args{j+1};
        case 'skip_initialize', skip_initialize = max(1, args{j+1}); 
        case 'fail_overlap', fail_overlap = args{j+1};            
        otherwise, error(['unrecognized argument ' args{j}]);
    end
end

start = 1;

total_time = 0;
total_frames = 0;

trajectory = cell(sequence.length, 1);

trajectory(:) = {0};

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

    failures = find(overlap' <= fail_overlap | ~isfinite(overlap'));
    failures = failures(failures > 1);

    trajectory(start) = {1};
        
    if ~isempty(failures)

        first_failure = failures(1) + start - 1;
        
        trajectory(start + 1:min(first_failure, size(Tr, 1) + start - 1)) = ...
            Tr(2:min(first_failure - start + 1, size(Tr, 1)));

        trajectory(first_failure) = {2};
        start = first_failure + skip_initialize;
                
        print_debug('INFO: Detected failure at frame %d.', first_failure);
        
        if ~isempty(skip_labels)
            for i = start:sequence.length
                if isempty(intersect(get_labels(sequence, i), skip_labels))
                    start = i;
                    break;
                end;                
            end;
        end;

        print_debug('INFO: Reinitializing at frame %d.', start);
    else
        
        if size(Tr, 1) > 1
            trajectory(start + 1:min(sequence.length, size(Tr, 1) + start - 1)) = ...
                Tr(2:min(sequence.length - start + 1, size(Tr, 1)));
        end;
        
        start = sequence.length;
    end;

    drawnow;
    
end;

time = total_time / total_frames;

end