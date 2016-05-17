function [] = main(varargin)

warning('off','all');

p = inputParser;
default.path = [];
addParamValue(p,'path',default.path,@ischar);
default.date = datestr(today+1,'mm/dd/yyyy');
addParamValue(p,'date',default.date,@ischar);
default.update = 0;
addParamValue(p,'update',default.update);
parse(p,varargin{:});
Path = p.Results.path;
InputDate = p.Results.date;
Update = p.Results.update;

javaaddpath(fullfile(Path,'ojdbc6_g.jar'));

try    
    if ischar(Update)
        Update = str2double(Update);
    end
    if Update~=0
        InputDate = datestr(datenum(InputDate)-abs(round(Update)),'mm/dd/yyyy');
    end

    [TestDate] = ConvertDate(InputDate);
    
    %**********%
    Update_WeatherData3(Path);
    %**********%
    
    Update_RecentTwoYearCrimeData(Path); 

    [Trend_hat,X,y,DummyIdx,HolidayIndicator] = Detrend2(TestDate,Path);

    Modelname1 = 'RVM Linear';
    [yhat1,Correction1] = ResidualPrediction(Modelname1,TestDate,X,y,DummyIdx,HolidayIndicator);
    Prediction1 = DailyPrediction(Trend_hat,yhat1,Correction1);

    Modelname2 = 'Lasso';
    [yhat2,Correction2] = ResidualPrediction(Modelname2,TestDate,X,y,DummyIdx,HolidayIndicator);
    Prediction2 = DailyPrediction(Trend_hat,yhat2,Correction2);

    Prediction1.SE = round(Prediction1.SE);
    Prediction1.CI = round(Prediction1.CI);
    Prediction2.SE = round(Prediction2.SE);
    Prediction2.CI = round(Prediction2.CI);
    PredVec = [Prediction1,Prediction2];
    Upload_Results2(PredVec,InputDate);
    
catch ME
    fid = fopen(fullfile(Path,'errlog.txt'),'a+');
    fprintf(fid,'Time: %s\t Error message: %s\n',datestr(now),ME.message);
    fclose(fid);  
    
    %Send_Email(fullfile(Path,'errlog.txt'))
end