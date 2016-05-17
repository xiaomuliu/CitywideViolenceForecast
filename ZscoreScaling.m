function [Xscale, X_mean, X_std] = ZscoreScaling(X, mu, sigma)

% INPUT
% X = matrix to normalize (rows = observations, columns = features)
% Scaling Parameters
% mu = the mean value, 
% sigma = the standard deviation

% OUTPUT
% Xnorm = normalized matrix. Standardize X  to mean 0 and standard
% deviation 1:
% Scaling Parameters
% X_mean = the mean of X, 
% X_std = the standard deviation of X

if nargin == 1
    X_mean = nanmean(X);
    X_std = nanstd(X);
else
    %using scaling factors from inputs
    X_mean = mu;
    X_std = sigma;
end

Xscale = (X-repmat(X_mean,size(X,1),1))./repmat(X_std,size(X,1),1);
% Mu = repmat(X_mean,size(X,1),1);
Xscale(isnan(Xscale)) = 0; %if X_std=0
