%% Mean-Shift Video Tracking
% by Sylvain Bernhardt
% July 2008
%% Description
% This is a simple example of how to use
% the Mean-Shift video tracking algorithm
% implemented in 'MeanShift_Algorithm.m'.
% It imports the video 'Ball.avi' from
% the 'Videos' folder and tracks a selected
% feature in it.
% The resulting video sequence is played after
% tracking, but is also exported as a AVI file
% 'Movie_out.avi' in the 'Videos' folder.

clear; close all; clc

%% Variables 
index_start = 1;
% Similarity Threshold
f_thresh = 0.16;
% Number max of iterations to converge
max_it = 5;
% Parzen window parameters
kernel_type = 'Gaussian';
radius = 1;

fid1 = fopen('images.txt','r'); %# open csv file for reading
IMGS = textscan(fid1, '%s');
fclose(fid1);

IMGS = IMGS{1};

Length = size(IMGS,1);

im0 = imread(IMGS{1});
height = size(im0,1);
width = size(im0,2);

bb_init = dlmread('region.txt');

fid2 = fopen('output.txt','w'); %# open csv file for writing

fprintf(fid2, '%f,%f,%f,%f\n', bb_init(1), bb_init(2), bb_init(3), bb_init(4));

T = imcrop(im0, bb_init);
x0 = bb_init(1);
y0 = bb_init(2);
W = bb_init(3);
H = bb_init(4);

%% Run the Mean-Shift algorithm
% Calculation of the Parzen Kernel window
[k,gx,gy] = Parzen_window(H,W,radius,kernel_type,0);
% Conversion from RGB to Indexed colours
% to compute the colour probability functions (PDFs)
[I,map] = rgb2ind(im0,65536);
Lmap = length(map)+1;
T = rgb2ind(T,map);
% Estimation of the target PDF
q = Density_estim(T,Lmap,k,H,W,0);
% Flag for target loss
loss = 0;
% Similarity evolution along tracking
f = zeros(1,(Length-1)*max_it);
% Sum of iterations along tracking and index of f
f_indx = 1;
% Draw the selected target in the first frame


%%%% TRACKING
% From 1st frame to last one
for t=1:Length-1
    t
    %TODO: read image
    im = imread(IMGS{t});
    imshow(im);
    % Next frame
    I2 = rgb2ind(im,map);
    % Apply the Mean-Shift algorithm to move (x,y)
    % to the target location in the next frame.
    [x,y,loss,f,f_indx] = MeanShift_Tracking(q,I2,Lmap,...
        height,width,f_thresh,max_it,x0,y0,H,W,k,gx,...
        gy,f,f_indx,loss);
    % Check for target loss. If true, end the tracking
    if loss == 1
        break;
    else
        % Drawing the target location in the next frame
        % Next frame becomes current frame
        y0 = y;
        x0 = x;
    end
    
    fprintf(fid2, '%f,%f,%f,%f\n', x0, y0, W, H);
    
    rectangle('Position', [x0 y0 W H], 'EdgeColor' , 'r');
    drawnow();
end
%%%% End of TRACKING

exit;