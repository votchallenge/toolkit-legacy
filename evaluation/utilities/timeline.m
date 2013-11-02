function [patchHndls] = timeline(lineNames,startTimes,endTimes,varargin)
%
% timeline.m--Draws horizontal timelines.
%
% PATCHHNDLS = TIMELINE(LINENAMES,STARTTIMES,ENDTIMES), with lineNames,
% startTimes and endTimes all being cell arrays of length n, draws n
% horizontal timelines in the current axes. The name of each timeline
% appears as a label on the y-axis. Each element of the startTimes and
% endTimes cell arrays is itself an array, so each timeline can start and
% stop either once or many times.
%
% ... = TIMELINE(...,'LINESPACING',LINESPACING), with lineSpacing a number
% between 0 and 1, places adjacent timelines the specified fraction of the
% line widths apart.
%
% ... = TIMELINE(...,patchArg1,patchArg2,...) passes the specified
% arguments directly to the patch command when drawing the timelines.
%
% Syntax: patchHndls = timeline(lineNames,startTimes,endTimes,<'lineSpacing',lineSpacing>,<patchArgs>)
%
% e.g.,   % Set up some dummy data for demonstration purposes.
%         lineNames={'Salinometer 1' 'Salinometer 2' 'Salinometer 3'};
%         startTimes={now-[800 500 100],now-600,now-[900 800 300 200]};
%         endTimes={startTimes{1}+[200 300 300],startTimes{2}+300,startTimes{3}+[80 400 50 250]};
%         % Call timeline.m.
%         patchHndls = timeline(lineNames,startTimes,endTimes,'lineSpacing',.1,'facecolor','b');
%         datetick('keeplimits'); title('Salinometer Deployments');
%         set(gcf,'position',[300 300 706 159]);

% Developed in Matlab 7.12.0.635 (R2011a) on GLNX86
% for the VENUS project (http://venus.uvic.ca/).
% Kevin Bartlett (kpb@uvic.ca), 2012-01-31 11:34
%-------------------------------------------------------------------------

p = inputParser;
p.KeepUnmatched=true;
p.FunctionName = mfilename;
p.addOptional('lineSpacing',1/4, @isnumeric);

try
    p.parse(varargin{:});
catch me
    disp([mfilename '.m--Parsing of input arguments failed; check argument names and values. Error message from inputParser follows:']);
    rethrow(me);
end

patchArgsStruct = p.Unmatched;
lineSpacing = p.Results.lineSpacing;

if lineSpacing<0 || lineSpacing>=1
    error([mfilename '.m--Line spacing must be between 0 and 1.']);
end

fieldNames = fieldnames(patchArgsStruct);
if ~ismember('edgecolor',lower(fieldNames))
   patchArgsStruct.edgeColor = 'k';
end 

if ~ismember('facecolor',lower(fieldNames))
    % Patch face colour not specified; use default.
   faceColor = 'r';
else
    % Patch face colour specified; extract in a variable and remove from
    % list of arguments to patch().
    for iField=1:length(fieldNames)
        thisFieldName = fieldNames{iField};
        if strcmpi(thisFieldName,'facecolor')
            faceColor = patchArgsStruct.(thisFieldName);
            patchArgsStruct = rmfield(patchArgsStruct,thisFieldName);
        end 
    end
end 

% Assemble a cell array of patch() arguments.
fieldNames = fieldnames(patchArgsStruct);
patchArgs = cell(1,2*length(fieldNames));
for iField=1:length(fieldNames)
    thisFieldName = fieldNames{iField};
    thisField = patchArgsStruct.(thisFieldName);
    patchArgs{(2*iField)-1} = thisFieldName;
    patchArgs{(2*iField)} = thisField;
end

numLines = length(lineNames);
%set(gca,'ydir','reverse');

LINE_HEIGHT = 1;
upperLeftCornerY = (lineSpacing + LINE_HEIGHT)*[0:(numLines-1)];
set(gca,'ylim',[0 max(upperLeftCornerY)+LINE_HEIGHT])
patchHndls = cell(1,numLines);

for iLine = 1:numLines
    thisLineName = lineNames{iLine};
    thisLineStartTimes = startTimes{iLine};
    thisLineEndTimes = endTimes{iLine};    
    thisULy = upperLeftCornerY(iLine);
    numPatches = length(thisLineStartTimes);
    thisLinePatchHndls = nan(1,numPatches);
    
    for iPatch = 1:numPatches
        thisPatchStartTime = thisLineStartTimes(iPatch);
        thisPatchEndTime = thisLineEndTimes(iPatch);
        thisPatchX = [thisPatchStartTime thisPatchEndTime thisPatchEndTime thisPatchStartTime thisPatchStartTime];
        thisPatchY = [thisULy thisULy thisULy+LINE_HEIGHT thisULy+LINE_HEIGHT thisULy];
        %thisLinePatchHndls(iPatch) = patch(thisPatchX,thisPatchY,'r','edgecolor','k');
        thisLinePatchHndls(iPatch) = patch(thisPatchX,thisPatchY,faceColor,patchArgs{:});
    end % for each patch
    
    patchHndls{iLine} = thisLinePatchHndls;

end % for each timeline

set(gca,'ytick',upperLeftCornerY+0.5*LINE_HEIGHT,'yticklabel',lineNames,'ylim', [0, numel(lineNames)+1]);

box on;
set(gca,'ygrid','on');

