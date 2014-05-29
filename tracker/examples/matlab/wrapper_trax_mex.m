function wrapper_trax_mex(tracker)
%% VOT integration example wrapper (TraX approach using MEX function)

% *************************************************************
% VOT: Always call exit command at the end to terminate Matlab!
% *************************************************************
cleanup = onCleanup(@() exit() );

% *************************************************************
% VOT: Set random seed to a different value every time.
% *************************************************************
RandStream.setGlobalStream(RandStream('mt19937ar', 'Seed', sum(clock)));

if nargin == 0  % Default tracker in the example is a reference NCC tracker
	tracker = 'ncc';
end;

% **********************************
% VOT: Initialize TraX protocol
% **********************************
traxserver('setup', 'rectangle', 'path');

tracker_initialize = str2func(['tracker_', tracker, '_initialize']);
tracker_update = str2func(['tracker_', tracker, '_update']);

state = [];

while 1

	% **********************************
	% VOT: Wait for instructions
	% **********************************
    [image, region] = traxserver('wait');

    if isempty(image) % QUIT request sent
		break;
	end;

	I = imread(image);

	try

		if isempty(region) % New frame
			if isempty(state) % Not initialized
				break;
			end;

		    [state, location] = tracker_update(state, I);

		else % Initialization

			% Initialize the tracker
			[state, location] = tracker_initialize(I, region);

		end

	catch

		location = [0, 0, 1, 1];

	end

	if isempty(location)
		location = [0, 0, 1, 1];
	end;

	% **********************************
	% VOT: Report status
	% **********************************
	traxserver('status', location);
end


