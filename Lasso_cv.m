function [beta, y_hat, r, lam_opt] = Lasso_cv(X, y, cp, lambda, varargin)

% input arguments
p = inputParser;
default.Standardize = true;
default.Categorical = false(1,size(X,2));
default.alpha=1;
default.opts = statset('UseParallel','always');

addRequired(p,'X',@isnumeric);
addRequired(p,'y',@isnumeric);
addRequired(p,'cp');
addRequired(p,'lambda',@isnumeric);

addParamValue(p,'Standardize',default.Standardize,@ischar);
addParamValue(p,'Categorical',default.Categorical,@islogical);
addParamValue(p,'alpha',default.alpha,@isnumeric);
addParamValue(p,'Options',default.opts);

parse(p, X, y, cp, lambda, varargin{:});

Standardize = p.Results.Standardize;
Categorical = p.Results.Categorical;
alpha = p.Results.alpha;
opts = p.Results.Options;

kfold = cp.NumTestSets;
        
RSS = zeros(kfold,length(lambda));

%Model Selection
for i = 1:length(lambda)
    for k = 1:kfold
        Tr_idx = cp.training(k);
        Te_idx = cp.test(k);
        XTrain = X(Tr_idx,:);
        XTest = X(Te_idx,:);
        yTrain = y(Tr_idx);
        yTest = y(Te_idx);
        
        if strcmpi(Standardize,'zscore1')
            [XTrain(:,~Categorical), X_mu, X_std] = ZscoreScaling(XTrain(:,~Categorical));
            XTest(:,~Categorical) = ZscoreScaling(XTest(:,~Categorical), X_mu, X_std);
        elseif strcmpi(Standardize,'zscore2')
            [XTrain, X_mu, X_std] = ZscoreScaling(XTrain);
            XTest = ZscoreScaling(XTest, X_mu, X_std);
        elseif strcmpi(Standardize,'minmax')
            [XTrain(:,~Categorical), Xmax, Xmin] = MinMaxScaling(XTrain(:,~Categorical));
            XTest(:,~Categorical) = MinMaxScaling(XTest(:,~Categorical), Xmax, Xmin);
        end
        
        %--------------
        [B,fitinfo] = lasso(XTrain,yTrain,'Lambda',lambda(i),'Options',opts,'Standardize',false,'Alpha',alpha);   
        B = [fitinfo.Intercept; B];
       
        XTest = x2fx(XTest,'linear');       
        y_hatTest = XTest*B; % Predict on the validation data

        %--------------                           
        RSS(k,i) = sum((y_hatTest-yTest).^2);
    end
end

MSE = mean(RSS,1);

%The optimal parameters with minimal MSE
[~, minIdx] = min(MSE);
lam_opt = lambda(minIdx);

%Now working on the entire training set
if strcmpi(Standardize,'zscore1')
    X(:,~Categorical) = zscore(X(:,~Categorical));
elseif strcmpi(Standardize,'zscore2')
    X = zscore(X);
elseif strcmpi(Standardize,'minmax')
    X(:,~Categorical) = MinMaxScaling(X(:,~Categorical));
end

[beta,fitinfo] = lasso(X, y, 'Lambda',lam_opt,'Options',opts,'Standardize',false,'Alpha',alpha);
beta = [fitinfo.Intercept; beta];
X = x2fx(X,'linear');
y_hat = X*beta;
%residual
r = y - y_hat;

