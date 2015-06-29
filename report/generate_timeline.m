function [handles] = generate_timeline(tracks, starts, ends, varargin)
% generate_timeline Generate a timeline plot with intervals.
% 
% Draws horizontal timeline in the current axes. The name of each track
% appears as a label on the y-axis. Each element of the starts and
% ends cell arrays is itself an array, so each track can start and
% stop either once or many times.
%
% Credit: Kevin Bartlett (kpb@uvic.ca), 2012
%
% Input:
% - tracks (cell): An array of timeline track names.
% - starts (cell): An array of vectors that indicate segment starts.
% - ends (cell): An array of vectors that indicate segment ends.
% - varargin[LineSpacing] (double): A number between 0 and 1, places 
% adjacent timelines the specified fraction of the line widths apart.
% - varargin[Color] (char): Color identifier for fill color.
%
% Output:
% - handles (cell): Handles of all segment rectangles.
%

line_spacing = 1/4;
face_color = 'r';

args = varargin;
for j = 1:2:length(args)
    switch lower(varargin{j})
        case 'linespacing', line_spacing = args{j+1}; 
        case 'color', face_color = args{j+1}; 
        otherwise, error(['Unknown switch ', varargin{j},'!']) ;
    end
end

if line_spacing < 0 || line_spacing >= 1
    error('Line spacing must be between 0 and 1.');
end

tracks_number = length(tracks);

line_height = 1;
corner_y = (line_spacing + line_height) * 0:(tracks_number-1);
set(gca,'ylim',[0 max(corner_y)+line_height])
handles = cell(1, tracks_number);

for i = 1:tracks_number
    track_starts = starts{i};
    track_ends = ends{i};    
    track_y = corner_y(i);
    segments_number = length(track_starts);
    track_segments = nan(1, segments_number);
    
    for j = 1:segments_number
        segment_x = [track_starts(j) track_ends(j) track_ends(j) track_starts(j) track_starts(j)];
        segment_y = [track_y track_y track_y+line_height track_y+line_height track_y];
        track_segments(j) = patch(segment_x, segment_y, face_color);
    end 
    
    handles{i} = track_segments;

end

set(gca,'ytick',corner_y+0.5*line_height,'yticklabel',tracks,'ylim', [0, numel(tracks)+1]);
box on;
set(gca,'ygrid','on');

