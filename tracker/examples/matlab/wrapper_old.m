function wrapper_old(tracker)
%% VOT integration example wrapper (old approach)

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
% VOT: Read input data
% **********************************
[images, region] = vot_tracker_initialize();

tracker_initialize = str2func(['tracker_', tracker, '_initialize']);
tracker_update = str2func(['tracker_', tracker, '_update']);

I = imread(images{1});

results = cell(length(images), 1);

% Initialize the tracker
[state, location] = tracker_initialize(I, region);

results{1} = location;

for i = 2:length(images)

    I = imread(images{i});

	% Perform an update step
    [state, location] = tracker_update(state, I);

    if isempty(location)
        location = 0;
    end;
    
    results{i} = location;
    
end;

% **********************************
% VOT: Output the results
% **********************************
vot_tracker_results(results);

