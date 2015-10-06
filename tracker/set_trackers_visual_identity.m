function [styled_trackers] = set_trackers_visual_identity(trackers, varargin)
% set_trackers_visual_identity Generate visual identity information
%
% Generate visual identity information for a set of trackers.
%
% Input:
% - trackers: Cell array of tracker structures.
% - varargin[Groups]: An array of group identifiers. A vector of the same length as the trackers cell array where each number denotes a group for the corresponding tracker. Trackers in the same group get the same color.
%
% Output:
% - styled_trackers: A modified cell array of tracker structures with their visualization information updated.

groups = [];

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'groups'
            groups = varargin{i+1};
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

if ~isempty(groups)
    if numel(groups) ~= numel(trackers)
        error('Group map not of correct size');
    end;
    
    [g, ia, ic] = unique(groups);
    
    colors = repmat(hsv(7), ceil(length(g) / 7), 1);
    
    colors = colors(ic ,:);
    
else
    colors = repmat(hsv(7), ceil(length(trackers) / 7), 1);
end

symbol = repmat({'o', 'x', '*', 'v', 'd', '+', '<', 'p', '>', 's', '^', 'h'}, 1, ceil(length(trackers) / 9));
width = mod(1:length(trackers), 5) / 5 + 1.5;

styled_trackers = cell(length(trackers), 1);

for i = 1:length(trackers)
    styled_trackers{i} = trackers{i};
    styled_trackers{i}.style.color = colors(i, :);
    styled_trackers{i}.style.symbol = symbol{i};
    styled_trackers{i}.style.width = width(i);
    styled_trackers{i}.style.font_color = [0, 0, 0];
    styled_trackers{i}.style.font_bold = false;
    if isfield(trackers{i}, 'label')
        styled_trackers{i}.label = trackers{i}.label;
    else
        styled_trackers{i}.label = trackers{i}.identifier;
    end;
end;
