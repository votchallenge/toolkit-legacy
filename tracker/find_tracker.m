function [index, tracker] = find_tracker(trackers, identifier)
% find_tracker Find a tracker by its identifier
%
% Find a tracker by its identifier in a cell array of tracker structures. Returns index of tracker and its structure.
% If a tracker is not found the function returns an empty matrix.
%
% Input:
% - trackers: Cell array of tracker structures.
% - identifiers: A string containing tracker identifier.
%
% Output:
% - index: Index of the tracker in the cell array or empty matrix if not found. 
% - tracker: The tracker structure.

index = find(cellfun(@(t) strcmp(t.identifier, identifier), trackers, 'UniformOutput', true), 1);

if isempty(index)
    tracker = [];
else
    tracker = trackers{index};
end;
