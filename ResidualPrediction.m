function [yhat,Correction] = ResidualPrediction(Modelname,TestDate,X,y,DummyIdx,HolidayIndicator)

% model initial setting
Model.name = Modelname;
[Model,arginHash] = ModelSettings(Model);

% set the random number generator seed and cross validation partition
Pred_datenum = datenum(TestDate.Year,TestDate.Month,TestDate.Day);
rng(Pred_datenum,'twister');
cp = cvpartition(size(X.train,1),'kfold', 10);
if ~strcmpi(Model.name,'Linear') && ~strcmpi(Model.name,'RVM Linear')
    arginHash('cp') = cp;
end
Scaling='minmax';

[yhat.test,yhat.testCI,yhat.testSE,Model.coeff] = PredictResidual(X,y,Model.name,arginHash,DummyIdx,Scaling);

if TestDate.Holiday~=0
    if TestDate.Holiday==1&&TestDate.Month~=1&&TestDate.Day~=1
        % Do not compensate when the new year observation is not on Jan 1st
        Correction = 0;
    else
        X.holiday = X.train_raw(HolidayIndicator==TestDate.Holiday,:);
        y.holiday = y.train_raw(HolidayIndicator==TestDate.Holiday,:);

        %"predict" past few years' holiday
        yhat.holiday = PredictHoliday(X,Model,DummyIdx,Scaling);
        Correction = mean(y.holiday-yhat.holiday);
    end
else
    Correction = 0;
end
