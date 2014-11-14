function [trackers] = change_trackers_visual_identity(trackers, identifiers, varargin)

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

for i = 1:numel(identifiers)
    t = find_tracker(trackers, identifiers{i});
    
    if isempty(t)
        continue;
    end
    
    trackers{t}.style.font_color = font_color;
    trackers{t}.style.font_bold = font_bold;
    
end