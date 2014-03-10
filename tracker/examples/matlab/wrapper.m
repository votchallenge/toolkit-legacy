function wrapper()
%% VOT integration example for MeanShift tracker

% *************************************************************
% VOT: Always call exit command at the end to terminate Matlab!
% *************************************************************
cleanup = onCleanup(@() exit() );

% *************************************************************
% VOT: Set random seed to a different value every time.
% *************************************************************
RandStream.setGlobalStream(RandStream('mt19937ar', 'Seed', sum(clock)));

tracker_directory = fullfile(fileparts(mfilename('fullpath')), 'tracker');
rmpath(tracker_directory);
addpath(tracker_directory);

% **********************************
% VOT: Read input data
% **********************************
[images, region] = vot_initialize();

%% Initialize tracker variables
index_start = 1;
% Similarity Threshold
f_thresh = 0.16;
% Number max of iterations to converge
max_it = 5;

count = size(images,1);

im0 = imread(images{1});
height = size(im0,1);
width = size(im0,2);

results = zeros(count, 4);

results(1, :) = region;

T = imcrop(im0, region);
x = region(1);
y = region(2);
W = region(3);
H = region(4);

%% Run the Mean-Shift algorithm
[k,gx,gy] = Parzen_window(H, W, 1, 'Gaussian', 0);
[I, map] = rgb2ind(im0, 65536);
Lmap = length(map) + 1;
T = rgb2ind(T,map);
% Estimation of the target PDF
q = Density_estim(T,Lmap,k,H,W,0);
% Flag for target loss
loss = 0;
% Similarity evolution along tracking
f = zeros(1, (count-1) * max_it);
% Sum of iterations along tracking and index of f
f_indx = 1;
% Draw the selected target in the first frame

% From 2nd frame to last one
for t=2:count

    if loss == 1
		results(t, :) = NaN;
		continue;
    else
		% Apply the Mean-Shift algorithm to move (x,y)
		% to the target location in the next frame.
		[x,y,loss,f,f_indx] = MeanShift_Tracking(q, ...
			rgb2ind(imread(images{t}), map),Lmap,...
		    height,width,f_thresh,max_it,x,y,H,W,k,gx,...
		    gy,f,f_indx,loss);
    end
	results(t, :) = [x, y, W, H];

end

vot_deinitialize(results);

