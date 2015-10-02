function p = gmm_evaluate(model, X)
% gmm_evaluate Evaluates the GMM for a set of points
%
% Input:
% - model (struct): A gaussian mixture model structure
% - X (matrix): Points for which to evaluate the model
%
% Output:
% - p (vector): values for corresponding points
%

[d, numData] = size(X); 
p = zeros(1,numData);
for i = 1 : length(model.w)
    iS = chol(inv(model.Cov{i}));
    logdetiS = sum(log(diag(iS)));
    logConstant = (logdetiS -0.5 * d * 1.83787706640935); % log2pi = 1.83787706640935
    dx = X - repmat(model.Mu(:,i), 1, numData);
    dx = iS * dx;
    pl = logConstant - 0.5 * sum(dx .* dx, 1);
    p_tmp = exp(pl);
    p = p + model.w(i) * p_tmp;
end


