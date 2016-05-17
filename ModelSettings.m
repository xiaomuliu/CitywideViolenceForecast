function [Model,arginHash] = ModelSettings(Model)

switch Model.name       
    case 'Lasso'
        Model.parameters = 2.^(-5:0.5:0.5); %lambda's
        alpha = 1;
        opts = statset('UseParallel','always');
        keys = {'lambda','alpha','options'};
        values = {Model.parameters,alpha,opts};
        arginHash = containers.Map(keys,values);
        
    case 'RVM Linear'       
        iterations	= 500;
        beta = 0.01; 
%         relevant = [];
%         weights = [];
%         alpha = [];

        Options = SB2_UserOptions('iterations',iterations);
        % SETTINGS = SB2_ParameterSettings('Beta',beta,'Relevant',relevant,'Weights',weights,'Alpha',alpha);
        % SETTINGS = SB2_ParameterSettings('NoiseStd',noiseStd);
        
        keys = {'hyperparam_beta','options'};
        values = {beta, Options};
        arginHash = containers.Map(keys,values);
               
end
