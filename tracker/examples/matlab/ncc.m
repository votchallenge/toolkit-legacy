function ncc
% ncc VOT integration example
% 
% This function is an example of tracker integration into the toolkit.
% The implemented tracker is a very simple NCC tracker that is also used as
% the baseline tracker for challenge entries.
%

% *************************************************************
% VOT: Always call exit command at the end to terminate Matlab!
% *************************************************************
cleanup = onCleanup(@() exit() );

% *************************************************************
% VOT: Set random seed to a different value every time.
% *************************************************************
RandStream.setGlobalStream(RandStream('mt19937ar', 'Seed', sum(clock)));

% **********************************
% VOT: Get initialization data
% **********************************
[handle, image, region] = vot('rectangle');

% Initialize the tracker
[state, ~] = ncc_initialize(imread(image), region);

while true

    % **********************************
    % VOT: Get next frame
    % **********************************
    [handle, image] = handle.frame(handle);

    if isempty(image)
        break;
    end;
    
	% Perform a tracking step, obtain new region
    [state, region] = ncc_update(state, imread(image));
    
    % **********************************
    % VOT: Report position for frame
    % **********************************
    handle = handle.report(handle, region);
    
end;

% **********************************
% VOT: Output the results
% **********************************
handle.quit(handle);

end

function [state, location] = ncc_initialize(I, region, varargin)

    gray = double(rgb2gray(I));

    [height, width] = size(gray);

    % If the provided region is a polygon ...
    if numel(region) > 4
        x1 = round(min(region(1:2:end)));
        x2 = round(max(region(1:2:end)));
        y1 = round(min(region(2:2:end)));
        y2 = round(max(region(2:2:end)));
        region = round([x1, y1, x2 - x1, y2 - y1]);
    else
        region = round([round(region(1)), round(region(2)), ... 
            round(region(1) + region(3)) - round(region(1)), ...
            round(region(2) + region(4)) - round(region(2))]);
    end;

    x1 = max(1, region(1));
    y1 = max(1, region(2));
    x2 = min(width-2, region(1) + region(3) - 1);
    y2 = min(height-2, region(2) + region(4) - 1);

    template = gray((y1:y2)+1, (x1:x2)+1);

    state = struct('template', template, 'size', [x2 - x1 + 1, y2 - y1 + 1]);
    state.window = max(state.size) * 2;
    state.position = [x1 + x2 + 1, y1 + y2 + 1] / 2;

    location = [x1, y1, state.size];

end

function [state, location] = ncc_update(state, I, varargin)

    gray = double(rgb2gray(I)) ; 

    [height, width] = size(gray);

    x1 = max(1, round(state.position(1) - state.window / 2));
    y1 = max(1, round(state.position(2) - state.window / 2));
    x2 = min(width-2, round(state.position(1) + state.window / 2));
    y2 = min(height-2, round(state.position(2) + state.window / 2));

    region = gray((y1:y2)+1, (x1:x2)+1);

    if any(size(region) < size(state.template))
        location = [state.position - state.size / 2, state.size];
        return;
    end;

    C = normxcorr2(state.template, region);

    % We are only using valid part of the response (where full template is used)
    pad = size(state.template) - 1;
    center = size(region) - pad - 1;
    C = C([false(1,pad(1)) true(1,center(1))], [false(1,pad(2)) true(1,center(2))]);

    x1 = x1 + pad(2);
    y1 = y1 + pad(1);
    [~, imax] = max(C(:));
    [my, mx] = ind2sub(size(C),imax(1));

    position = [x1 + mx - state.size(1) / 2, y1 + my - state.size(2) / 2];

    state.position = position;
    location = [position - state.size / 2, state.size];

end
