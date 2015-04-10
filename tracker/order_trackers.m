function [trackers, indices] = order_trackers(trackers, order)

if nargin < 2
    order = 'identifier_ascending';
end;

switch order
    case 'identifier_ascending'
        identifiers = cellfun(@(t) t.identifier, trackers, 'UniformOutput', false);
        [~, indices] = sort(identifiers);
    case 'identifier_descending'
        identifiers = cellfun(@(t) t.identifier, trackers, 'UniformOutput', false);
        [~, indices] = sort(identifiers);
        indices = fliplr(indices);
    otherwise
        return;
end;

trackers = trackers(indices);