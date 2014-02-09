function [trackers] = create_trackers(list_file)

identifiers = readfile(list_file, ',');

identifiers = identifiers(:);

trackers = cell(size(identifiers, 1), 1);

for i = 1:size(identifiers, 1)
    tracker_identifier = strtrim(identifiers{i});
    
    if isempty(tracker_identifier)
        break;
    end

    if ~valid_identifier(tracker_identifier)
        print_debug('%s is not a valid tracker identifier. Skipping.', ...
            tracker_identifier);
        continue;
    end;
    
    trackers{i} = create_tracker(tracker_identifier);
    
end;

trackers = set_trackers_visual_identity(trackers);
