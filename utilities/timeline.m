function [patchHndls] = timeline(lineNames, startTimes, endTimes, varargin)
%
% HANDLES = TIMELINE(LINENAMES,STARTTIMES,ENDTIMES), with lineNames,
% startTimes and endTimes all being cell arrays of length n, draws n
% horizontal timelines in the current axes. The name of each timeline
% appears as a label on the y-axis. Each element of the startTimes and
% endTimes cell arrays is itself an array, so each timeline can start and
% stop either once or many times.
%
% ... = TIMELINE(...,'LINESPACING',LINESPACING), with line_spacing a number
% between 0 and 1, places adjacent timelines the specified fraction of the
% line widths apart.
%
% Credit: Kevin Bartlett (kpb@uvic.ca), 2012
% Modified by: Luka Cehovin
%-------------------------------------------------------------------------

line_spacing = 1/4;
face_color = 'r';

args = varargin;
for j=1:2:length(args)
    switch lower(varargin{j})
        case 'linespacing', line_spacing = args{j+1}; 
        case 'color', face_color = args{j+1}; 
        otherwise, error(['Unknown switch ', varargin{j},'!']) ;
    end
end

if line_spacing < 0 || line_spacing >= 1
    error('Line spacing must be between 0 and 1.');
end

numLines = length(lineNames);

line_height = 1;
upperLeftCornerY = (line_spacing + line_height)*[0:(numLines-1)];
set(gca,'ylim',[0 max(upperLeftCornerY)+line_height])
patchHndls = cell(1,numLines);

for iLine = 1:numLines
    thisLineStartTimes = startTimes{iLine};
    thisLineEndTimes = endTimes{iLine};    
    thisULy = upperLeftCornerY(iLine);
    numPatches = length(thisLineStartTimes);
    thisLinePatchHndls = nan(1,numPatches);
    
    for iPatch = 1:numPatches
        thisPatchStartTime = thisLineStartTimes(iPatch);
        thisPatchEndTime = thisLineEndTimes(iPatch);
        thisPatchX = [thisPatchStartTime thisPatchEndTime thisPatchEndTime thisPatchStartTime thisPatchStartTime];
        thisPatchY = [thisULy thisULy thisULy+line_height thisULy+line_height thisULy];
        %thisLinePatchHndls(iPatch) = patch(thisPatchX,thisPatchY,'r','edgecolor','k');
        thisLinePatchHndls(iPatch) = patch(thisPatchX, thisPatchY, face_color);
    end % for each patch
    
    patchHndls{iLine} = thisLinePatchHndls;

end % for each timeline

set(gca,'ytick',upperLeftCornerY+0.5*line_height,'yticklabel',lineNames,'ylim', [0, numel(lineNames)+1]);

box on;
set(gca,'ygrid','on');

