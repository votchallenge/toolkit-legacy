function [handle, image, region] = vot(format, channels)
% vot Initialize communication and obtain communication structure
%
% This function is used to initialize communication with the toolkit.
%
% The resulting handle is a structure provides several functions for
% further interaction:
% - frame(handle): Get new frame from the sequence.
% - report(handle, region): Report region for current frame and advance.
% - quit(handle): Closes the communication and saves the data.
%
% Input:
% - format (string): Desired region input format.
% - channels (string): Which channels are required by the trackers
%     - (default): only color
%     - rgbd: color and depth
%     - ir: only ir
%     - rgbt: color and ir
%
% Output:
% - handle (structure): Updated communication handle structure.
% - image (string): Path to the first image file.
% - region (vector): Initial region encoded as a rectangle or as a polygon.

    if nargin < 1
       format = 'rectangle';
    end

    if nargin < 2 || strcmp(channels, 'color')
       channels = {'color'};
    elseif strcmp(channels, 'rgbd')
        channels = {'color', 'depth'};
    elseif strcmp(channels, 'ir')
        channels = {'ir'};
    elseif strcmp(channels, 'rgbt')
        channels = {'color', 'ir'};
    end

    [handle, image, region] = tracker_initialize(format, channels);
    handle.frame = @tracker_frame;
    handle.report = @tracker_report;
    handle.quit = @tracker_quit;

end

function [handle, image, region] = tracker_initialize(format, channels)
% tracker_initialize Initialize communication structure
%
% This function is used to initialize communication with the toolkit.
%
% Input:
% - format (string): Desired region input format.
% - channels (string, cell): Which channels are required by the trackers
%
% Output:
% - handle (structure): Updated communication handle structure.
% - image (string): Path to the first image file.
% - region (vector): Initial region encoded as a rectangle or as a polygon.

    if ~ismember(format,  {'rectangle', 'polygon'})
        error('VOT: Illegal region format.');
    end;

    if ~all(ismember(channels,  {'color', 'depth', 'ir'}))
        error('VOT: Illegal channel type.');
    end;

    if ~isempty(getenv('TRAX_MEX'))
        addpath(getenv('TRAX_MEX'));
    end;

    traxserver('setup', format, 'path', 'Channels', channels);

    [image, region] = traxserver('wait');

    handle = struct('trax', true);

    if isempty(image) || isempty(region)
        tracker_quit(handle);
        return;
    end;

    if iscell(image) && numel(image) == 1
        image = image{1}
    end;

	handle.initialization = region;

end

function [handle, image] = tracker_frame(handle)
% tracker_frame Get new frame from the sequence
%
% This function is used to get new frame from the current sequence
%
% Input:
% - handle (structure): Communication handle structure.
%
% Output:
% - handle (structure): Updated communication handle structure.
% - image (string): Path to image file.

    if ~isstruct(handle)
        error('VOT: Handle should be a structure.');
    end;

	if ~isempty(handle.initialization)
	    traxserver('status', handle.initialization);
		handle.initialization = [];
	end;

    [image, region] = traxserver('wait');

    if isempty(image) || ~isempty(region)
        handle.quit(handle);
    end;

    if iscell(image) && numel(image) == 1
        image = image{1}
    end;

end

function handle = tracker_report(handle, region, confidence)
% tracker_report Report region for current frame and advance
%
% This function stores the region for the current frame and advances
% the internal counter to the next frame.
%
% Input:
% - handle (structure): Communication handle structure.
% - region (vector): Predicted region as a rectangle or a polygon.
% - confidence (float): Optional number that indicates confidence of prediction.
%   Can be on arbitrary scale, higher value means more confidence.
%
% Output:
% - handle (structure): Updated communication handle structure.

    if isempty(region)
        region = 0;
    end;

    if ~isstruct(handle)
        error('VOT: Handle should be a structure.');
    end;

	if ~isempty(handle.initialization)
		handle.initialization = [];
	end;

    parameters = struct();

    if nargin > 2
        parameters.confidence = confidence;
    end

    traxserver('status', region, parameters);

end


function tracker_quit(handle)
% tracker_quit Closes the communication and saves the data
%
% This function closes the communication with the toolkit and
% saves the remaining data.
%
% Input:
% - handle (structure): Communication handle structure.
%

    if ~isstruct(handle)
        error('VOT: Handle should be a structure.');
    end;

    traxserver('quit');

end
