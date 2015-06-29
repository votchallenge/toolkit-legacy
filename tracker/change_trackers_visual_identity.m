function [trackers] = change_trackers_visual_identity(trackers, identifiers, varargin)
% change_trackers_visual_identity Modify the visualization properties
%
% Modify the visualization properties of a tracker or a set of trackers.
%
% Input:
% - trackers: Cell array of tracker structures.
% - identifiers: A string or a cell array of strings containing tracker identifiers.
% - varargin[FontColor]: A triple indicating a color of the font used.
% - varargin[FontBold]: A boolean indicating if using bold font.
%
% Output:
% - trackers: A modified cell array of tracker structures.

font_color = [0, 0, 0];
font_bold = false;

for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'fontcolor'
            font_color = varargin{i+1};
        case 'fontbold'
            font_bold = varargin{i+1};            
        otherwise 
            error(['Unknown switch ', varargin{i},'!']) ;
    end
end 

if ~iscell(identifiers)
    identifiers = {identifiers};
end

for i = 1:numel(identifiers)
    t = find_tracker(trackers, identifiers{i});
    
    if isempty(t)
        continue;
    end
    
    trackers{t}.style.font_color = font_color;
    trackers{t}.style.font_bold = font_bold;
    
end
