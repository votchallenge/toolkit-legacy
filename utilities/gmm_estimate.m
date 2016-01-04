function model = gmm_estimate(data)
% gmm_estimate Estimates a GMM on a set of points
%
% Originally a part of: Maggot (developed within EU project CogX)
% Original author: Matej Kristan, 2009
%
% Input:
% - data (matrix): Points for which to estimate a model
%
% Output:
% - model (vector): values for corresponding points
%

N = length(data);
model.Mu = data;
model.Cov{N} = cell(N, 1);
for i = 1:N
    model.Cov{i} = 0;
end
model.w = ones(1,N) / N;

pdf0 = model;

% first we'll spherize the distribution
[Mu, C] = spherize(pdf0.Mu, pdf0.Cov, pdf0.w) ;
[U, S, V] = svd(C) ;
T = (diag(1./sqrt(diag(S))))*U' ;

pdf0.Mu = bsxfun(@minus, pdf0.Mu, Mu) ;
pdf0.Mu = T * pdf0.Mu ;
for i = 1 : length(pdf0.w)
    pdf0.Cov{i} = T*pdf0.Cov{i}*T' ;
end

C = T*C*T' ;
% calculate the optimal bandwidth by Kristan's estimator
H = optimal_bandwidth( pdf0.Mu, pdf0.Cov, pdf0.w, C, length(pdf0.w)) ;

pdf.Mu = Mu ;
pdf.Cov = {H} ;
pdf.w = 1 ;

iT = inv(T) ;
pdf.Mu = iT * pdf.Mu ;
pdf.Mu = bsxfun(@minus, pdf.Mu, -Mu) ;
for i = 1 : length(pdf.w)
    pdf.Cov{i} = iT * pdf.Cov{i} * iT';
end
H = pdf.Cov{1} ;

for i = 1:N
    model.Cov{i} = H ;
end

end

function [new_mu, new_Cov] = spherize(Mu, Cov, w)

if length(w)==1
    new_mu = Mu ;
    if ~isempty(Cov)
        new_Cov = Cov{1} ;
    else
        new_Cov = zeros(size(new_mu,1),size(new_mu,1)) ;
    end
    return ;
end

sumw = sum(w) ;
w = w / sumw ;
new_mu =  sum(bsxfun(@times,Mu, w),2) ;

n = size(new_mu,1) ;

if ~isempty(Cov)
    new_Cov = zeros(n,n) ;
    if n==1
        new_Cov = sum(w.*(cell2mat(Cov) + Mu.*Mu)) ;
    else
        for j=1:length(w)
            new_Cov = new_Cov + w(j)*( Cov{j} + Mu(:,j)*Mu(:,j)') ;
        end
    end
    new_Cov = new_Cov - new_mu*new_mu' ;
else
    new_Cov = zeros(n,n) ;
    if n==1
        new_Cov = sum(w.*(Mu.*Mu)) ;
    else
        for j=1:length(w)
            new_Cov = new_Cov + w(j)*(   Mu(:,j)*Mu(:,j)') ;
        end
    end
    new_Cov = new_Cov - new_mu*new_mu' ;
    
end

end

function [H] = optimal_bandwidth( Mu, Cov, w, Cov_smp, N_eff )

d = size(Mu,1) ;
G = (Cov_smp *(4 / ((d + 2) * N_eff))^(2 / (d + 4)));

alpha_scale = 1 ;
F = Cov_smp * alpha_scale; % for numerical stability. it could have been: F = Cov_smp;
% could also constrain to say that F = identity!
Rf2 = integral_squared_hessian(Mu, w, Cov, F, G);

h_amise = (N_eff ^ (-1) * det(F)^(-1 / 2) /( sqrt(4 * pi) ^ d * Rf2 * d ))^(1 / (d + 4)) ;
H = (F * h_amise ^ 2) * alpha_scale ;

end

function I = integral_squared_hessian(Mu, w, Cov, F, G)
% Calculates an integral over the squared Hessian of a Gaussian mixture
% model.
% Follows Wand and Jones "Kernel Smoothing", page 101., assuming H=h*F.

I = NaN ;
if ( isempty(Mu) )
    return;
end
% read dimension and number of components
[ d, N ]= size(Mu) ;

% precompute normalizer constNorm = ( 1 / 2pi)^(d/2)
constNorm = (1/(2*pi))^(d/2) ;
I = 0 ;

% test if F is identity for speedup
delta_F = sum(sum(abs(F-eye(size(F))))) ;
if delta_F < 1e-3
    % generate a summation over the nonsymmetric matrix
    for l1 = 1 : N
        S1 = Cov{l1}  + G ;
        Mu1 = Mu(:,l1) ;
        w1 = w(l1) ;
        for l2 = l1 : N
            S2 = Cov{l2};
            Mu2 = Mu(:,l2) ;
            w2 = w(l2) ;
            A = inv(S1 + S2) ;
            dm = (Mu1 - Mu2) ;
            m = dm'*A*dm ;
            f_t = constNorm*sqrt(det(A))*exp(-0.5*m) ;
            c = 2*sum(sum(A.*A'))*(1-2*m) + (1-m)^2 *trace(A)^2 ;
            
            % determine the weight of the term current
            if ( l1 == l2 )
                eta = 1 ;
            else
                eta = 2 ;
            end
            I = I + f_t*c*w2*w1*eta ;
        end
    end
else
    % generate a summation over the nonsymmetric matrix
    for l1 = 1 : N
        S1 = Cov{l1} ;
        Mu1 = Mu(:,l1) ;
        w1 = w(l1) ;
        for l2 = l1 : N
            S2 = Cov{l2} + G;
            Mu2 = Mu(:,l2) ;
            w2 = w(l2) ;
            A = inv(S1 + S2) ;
            dm = (Mu1 - Mu2) ;
            ds = dm'*A ;
            b = ds'*ds ;
            B = A - 2*b ;
            C = A - b ;
            
            f_t = constNorm*sqrt(det(A))*exp(-0.5*ds*dm) ;
            c = 2*trace(F*A*F*B) + trace(F*C)^2 ;
            
            % determine the weight of the term current
            if ( l1 == l2 )
                eta = 1 ;
            else
                eta = 2 ;
            end
            I = I + f_t*c*w2*w1*eta ;
        end
    end
end

end
