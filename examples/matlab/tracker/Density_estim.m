%% Mean-Shift Video Tracking
% by Sylvain Bernhardt
% July 2008
%% Description
% Estimate the density of data samples
% (here colour histogram) in a patch T
% with a kernel profile k. Lmap is the
% colormap length and H,W the patch size.

function q = Density_estim(T,Lmap,k,H,W,graph)
q = zeros(Lmap,1);
colour = linspace(1,Lmap,Lmap);
for x=1:W
    for y=1:H 
        q(T(y,x)+1) = q(T(y,x)+1)+k(y,x);
    end
end

% Normalizing
C = 1/sum(sum(k));
q = C.*q;

% Plotting the estimated densities
if graph==1
    figure
    plot(colour,q);
end