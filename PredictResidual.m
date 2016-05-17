function [y_hat_test,CI,SE,Modelcoef] = PredictResidual(X,y,Modelname,arginHash,DummyIdx,Scaling)

switch Modelname             
    case {'Lasso'}
        lambda = arginHash('lambda');
        alpha = arginHash('alpha');
        cp = arginHash('cp');
        opts = arginHash('options');
        
        [beta, ~, r, ~] = Lasso_cv(X.train, y.train, cp, lambda,...
            'Standardize',Scaling,'Categorical',DummyIdx,'alpha',alpha,'Options',opts);
        
        if strcmpi(Scaling,'zscore1') 
            [X.train(:,~DummyIdx), mu, sigma] = ZscoreScaling(X.train(:,~DummyIdx));
            X.test(:,~DummyIdx) = ZscoreScaling(X.test(:,~DummyIdx), mu, sigma);
        elseif strcmpi(Scaling,'zscore2')
            [X.train, mu, sigma] = ZscoreScaling(X.train);
            X.test = ZscoreScaling(X.test, mu, sigma);
        elseif strcmpi(Scaling,'minmax')
            [X.train(:,~DummyIdx), Xmax, Xmin] = MinMaxScaling(X.train(:,~DummyIdx));
            X.test(:,~DummyIdx) = MinMaxScaling(X.test(:,~DummyIdx), Xmax, Xmin);
        end
        
        X.train = x2fx(X.train,'linear');
        X.test = x2fx(X.test,'linear');       
        y_hat_test = X.test*beta; 
       
        % confidence interval
        X.train = X.train(:,beta'~=0);
        X.test = X.test(:,beta'~=0);
        [N,P] = size(X.train);
        DoF = N-P;
        SE = sqrt(1/DoF*(r'*r));         
        mse = mean(r.^2);
        CI = tinv(0.975,DoF)*sqrt(mse*(1+X.test/(X.train'*X.train)*X.test'));
        
        Modelcoef = beta';
               
    case 'RVM Linear'
    % ----------- Bayesian Linear ------------
        beta = arginHash('hyperparam_beta');
        Options = arginHash('options');
        
        Settings = SB2_ParameterSettings('Beta', beta);

        if strcmpi(Scaling,'zscore1') 
            [X.train(:,~DummyIdx), mu, sigma] = ZscoreScaling(X.train(:,~DummyIdx));
            X.test(:,~DummyIdx) = ZscoreScaling(X.test(:,~DummyIdx), mu, sigma);
        elseif strcmpi(Scaling,'zscore2')
            [X.train, mu, sigma] = ZscoreScaling(X.train);
            X.test = ZscoreScaling(X.test, mu, sigma);
        elseif strcmpi(Scaling,'minmax')
            [X.train(:,~DummyIdx), Xmax, Xmin] = MinMaxScaling(X.train(:,~DummyIdx));
            X.test(:,~DummyIdx) = MinMaxScaling(X.test(:,~DummyIdx), Xmax, Xmin);
        end
        
        X.train = x2fx(X.train,'linear');
        X.test = x2fx(X.test,'linear');

        [Parameter, ~] = ...
            SparseBayes('Gaussian', X.train, y.train, Options, Settings);

        % Manipulate the returned weights for convenience later
        w = zeros(size(X.train,2),1);
        w(Parameter.Relevant) = Parameter.Value;

        y_hat_test = X.test*w;

        % confidence interval
        y_hat_train = X.train*w;
        r = y_hat_train-y.train;
        DoF = size(X.train,1)-length(Parameter.Relevant);
        SE = sqrt(1/DoF*(r'*r));
        X.train = X.train(:,w'~=0);
        X.test = X.test(:,w'~=0);
        mse = mean(r.^2);
        CI = tinv(0.975,DoF)*sqrt(mse*(1+X.test/(X.train'*X.train)*X.test'));
        
        Modelcoef = w';
               
end


