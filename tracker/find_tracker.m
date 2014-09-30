function [index, tracker] = find_tracker(trackers, identifier)

index = find(cellfun(@(t) strcmp(t.identifier, identifier), trackers, 'UniformOutput', true), 1);

if isempty(index)
    tracker = [];
else
    tracker = trackers{index};
end;
