function [Xnorm, X_max, X_min] = MinMaxScaling(X, high, low)

% © 2011 Illinois Institute of Technology

% INPUT
% X = matrix to normalize (rows = observations, columns = features)
% Scaling Parameters

% OUTPUT
% Xnorm = normalized matrix
% X_max = the max value of each column of X
% X_min = the min value of each column of X

if nargin == 1
    X_max = max(X,[],1);
    X_min = min(X,[],1);
else
    X_max = high;
    X_min = low;
end

Xnorm = (X-repmat(X_min,size(X,1),1))./repmat((X_max-X_min),size(X,1),1);

Xnorm(isnan(Xnorm))=0.5; %if Xmax==Xmin;