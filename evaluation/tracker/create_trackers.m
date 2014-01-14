function [trackers] = create_trackers(list_file)

fid = fopen(list_file, 'r');

results_directory = fullfile(get_global_variable('directory'), 'results');

trackers = cell(0,0);

while true
    tracker_name = fgetl(fid);
    if tracker_name == -1
        break;
    end

    trackers{end+1} = create_tracker(tracker_name, fullfile(results_directory, tracker_name));

end;

fclose(fid);

trackers = set_trackers_visual_identity(trackers);
