%% Mean-Shift Video Tracking
% by Sylvain Bernhardt
% July 2008
%% Description
% Tracks a patch 'T' in a video sequence 'Movie'
% using the Mean-Shift algorithm.
% f is the similiraty function between the original patch
% and the candidate ones along the video sequence.
%
% [x,y,loss,f,f_indx] = MeanShift_Tracking(q,I2,Lmap,...
%     height,width,f_thresh,max_it,x0,y0,H,W,k,gx,gy,...
%     f,f_indx,loss)
% with:
% (x,y) - the location of the target in the frame I2
% (f,f_indx) - storing the evolution of similarity
% loss - flag for target loss
% q - PDF of the reference target
% I2 - the next frame
% Lmap - length of colormap, also number of bins for PDF
% height,width - size of I2
% f_thresh - the similarity threshold
% max_it - the maximum number of iterations
% x0,y0 - the location of the target
% H,W - its size
% (k,gx,gy) - kernel mask and its gradients

function [x,y,loss,f,f_indx] = MeanShift_Tracking(q,I2,Lmap,...
    height,width,f_thresh,max_it,x0,y0,H,W,k,gx,gy,f,f_indx,...
    loss)
% Initialization in the next frame from the
% same location than in the current frame.
y = y0;
x = x0;
T2 = I2(y:y+H-1,x:x+W-1);
p = Density_estim(T2,Lmap,k,H,W,0);
% Number of iterations
step = 1;
% Computation of the similarity value
% between the two PDF.
[fi,w] = Simil_func(q,p,T2,k,H,W);
f = cat(2,f,fi);
% Applying Mean-shift algorithm
while f(f_indx)<f_thresh && step<max_it
    step = step+1;
    f_indx = f_indx+1;
    num_x = 0;
    num_y = 0;
    den = 0;
    for i = 1:H
        for j=1:W
            num_x = num_x+i*w(i,j)*gx(i,j);
            num_y = num_y+j*w(i,j)*gy(i,j);
            den = den+w(i,j)*norm([gx(i,j) gy(i,j)]);
        end
    end
    % Displacement vector (dx,dy) on the gradient ascent
    if den ~= 0
        dx = round(num_x/den);
        dy = round(num_y/den);
        y = y+dy;
        x = x+dx;
    end
    % Detection of target loss or out of frame boundaries
    if (y<1 || y>height-H) || (x<1 || x>width-W)
        loss = 1;
        Target_Loss_Dialog_Box();
        uiwait(Target_Loss_Dialog_Box);
        break;
    end
    % Update the target
    T2 = I2(y:y+H-1,x:x+W-1);
    p = Density_estim(T2,Lmap,k,H,W,0);
    [fi,w] = Simil_func(q,p,T2,k,H,W);
    f = cat(2,f,fi);
end
