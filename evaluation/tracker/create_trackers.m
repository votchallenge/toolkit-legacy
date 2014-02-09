function [trackers] = create_trackers(list_file)


results_directory = fullfile(get_global_variable('directory'), 'results');

fc = readfile(list_file, ',');

trackers = cell(size(fc, 1), 1);

for i = 1:size(fc, 1)
    tracker_name = strtrim(fc{i, 1});
    
    if isempty(tracker_name)
        break;
    end

    trackers{i} = create_tracker(tracker_name, fullfile(results_directory, tracker_name));
    
    if size(fc, 2) > 1
        trackers{i}.label = strtrim(fc{i, 2});
    end;
    
end;

trackers = set_trackers_visual_identity(trackers);
