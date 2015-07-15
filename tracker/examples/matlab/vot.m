function [handle, image, region] = vot(format)
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
%
% Output:
% - handle (structure): Updated communication handle structure.
% - image (string): Path to the first image file.
% - region (vector): Initial region encoded as a rectangle or as a polygon.

    if nargin < 1
       format = 'rectangle'; 
    end

    [handle, image, region] = tracker_initialize(format);
    handle.frame = @tracker_frame;
    handle.report = @tracker_report;
    handle.quit = @tracker_quit;
    
end

function [handle, image, region] = tracker_initialize(format)
% tracker_initialize Initialize communication structure
%
% This function is used to initialize communication with the toolkit.
%
% Input:
% - format (string): Desired region input format.
%
% Output:
% - handle (structure): Updated communication handle structure.
% - image (string): Path to the first image file.
% - region (vector): Initial region encoded as a rectangle or as a polygon.

    if ~ismember(format,  {'rectangle', 'polygon'})
        error('VOT: Illegal region format.');
    end;

    if ~isempty(getenv('TRAX'))
        % In case TraX can be used, we include the path to the server mex function.
        if ~isempty(getenv('TRAX_MEX'))
            addpath(getenv('TRAX_MEX'));
        end;
        traxserver('setup', format, 'path');

        [image, region] = traxserver('wait');

        handle = struct('trax', true);
        
        if isempty(image) || isempty(region)
            tracker_quit(handle);
            return;
        end;

        traxserver('status', region);
        
        return;
    end;

    handle.trax = false;

    % read the image file paths
    fid = fopen('images.txt','r'); 
    images = textscan(fid, '%s', 'delimiter', '\n');
    fclose(fid);
    handle.images = images{1};

    % read the region
    region = dlmread('region.txt');
    region = region(:);
    handle.format = format;
    handle.index = 2;
    handle.regions = cell(numel(handle.images), 1);

    if numel(region) == 4
        format = 'rectangle';
    elseif numel(region) >= 6 && mod(numel(region), 2) == 0
        format = 'polygon';
    else
        error('VOT: Illegal format of the input region.');
    end;

    switch handle.format
        case 'rectangle'
            if strcmp(format, 'polygon')
                x = region(1:2:end);
                y = region(2:2:end);
                region = [min(x), min(y), max(x) - min(x), max(y) - min(y)];
            end;
        case 'polygon'
            if strcmp(format, 'rectangle')
                x = [region(1), region(1), region(1) + region(3), ...
                     region(1) + region(3), region(1)];
                y = [region(2), region(2) + region(4), region(2) + ...
                     region(4), region(2), region(2)];
                region = zeros(8, 1);
                region(1:2:7) = x;
                region(2:2:8) = y;
            end;
    end;

    handle.position = 2;
    
    handle.regions{1} = region;
    image = handle.images{1};

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

    if handle.trax
        [image, region] = traxserver('wait');

        if isempty(image) || ~isempty(region)
            handle.quit(handle);
        end;

        return;
    end;

    if handle.position > numel(handle.images)
        image = [];
        return;
    end;
    
    image = handle.images{handle.position};

end

function handle = tracker_report(handle, region)
% tracker_report Report region for current frame and advance
%
% This function stores the region for the current frame and advances
% the internal counter to the next frame.
%
% Input:
% - handle (structure): Communication handle structure.
% - region (vector): Predicted region as a rectangle or a polygon.
%
% Output:
% - handle (structure): Updated communication handle structure.

    if isempty(region)
        region = 0;
    end;

    if ~isstruct(handle)
        error('VOT: Handle should be a structure.');
    end;

    if handle.trax
        traxserver('status', region);
        return;
    end;

    if handle.position > numel(handle.images)
        return;
    end;
    
    handle.regions{handle.position} = region;

    handle.position = handle.position + 1;
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

    if handle.trax
        traxserver('quit');
        return;
    end;

    if iscell(handle.regions)

        fid = fopen('output.txt', 'w');

        for i = 1:numel(handle.regions)
            region = handle.regions{i};

            if numel(region) == 1
                fprintf(fid, '%f\n', region);
            elseif numel(region) == 4
                fprintf(fid, '%f,%f,%f,%f\n', region(1), region(2), region(3), region(4));
            elseif numel(region) >= 6 && mod(numel(region), 2) == 0
                fprintf(fid, '%f,', region(1:end-1));
                fprintf(fid, '%f\n', region(end));
            else
                error('VOT: Illegal result format');
            end;

        end;

        fclose(fid);

        quit();
    else
        error('VOT: Unable to write results.');
    end

end
