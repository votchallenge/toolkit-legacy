%% Mean-Shift Video Tracking
% by Sylvain Bernhardt
% July 2008
%% Description
% Measures the similarity between two
% density estimations q and p done with
% a kernel which profile is k.
% q is the estimation of a reference patch
% and p the estimation of a candidate one 'T2'
% which size is H,W.
% The outputs are the similarity value f
% and the weight mask w for the gradient ascent
% in the extended Mean-Shift algorithm.
%
% [f,w] = Simil_func(q,p,T2,k,H,W)

function [f,w] = Simil_func(q,p,T2,k,H,W)

w = zeros(H,W);
f = 0;
for i=1:H
    for j=1:W
        w(i,j) = sqrt(q(T2(i,j)+1)/p(T2(i,j)+1));
        f = f+w(i,j)*k(i,j);
    end
end
% Normalization of f
f = f/(H*W);