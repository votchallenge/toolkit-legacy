function [trackers, indices] = order_trackers(trackers, order)
% order_trackers Change the order of trackers
%
% Change the order of trackers in a cell array of tracker structures.
%
% The functions upports the following ordering options:
%
% - IdentifierAscending
% - IdentifierDescending
%
% Input:
% - trackers: Cell array of tracker structures.
% - order: A string that defines the order of trackers. See the description above for available options.
%
% Output:
% - trackers: A modified cell array of tracker structures.
% - indices: The mapping from the old to the new array.

if nargin < 2
    order = 'identifierascending';
end;

order = lower(order);

switch order
    case 'identifierascending'
        identifiers = cellfun(@(t) t.identifier, trackers, 'UniformOutput', false);
        [~, indices] = sort(identifiers);
    case 'identifierdescending'
        identifiers = cellfun(@(t) t.identifier, trackers, 'UniformOutput', false);
        [~, indices] = sort(identifiers);
        indices = fliplr(indices);
    otherwise
        return;
end;

trackers = trackers(indices);
