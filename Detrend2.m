function [Trend_hat,X,y,DummyIdx,HolidayIndicator] = Detrend2(TestDate,Path)

% Load crime and weather data
CrimeFilename = fullfile(Path,'Crimes_All.csv');
fid = fopen(CrimeFilename);
tline = fgetl(fid);
CrimeField = regexp(tline, ',', 'split');
CrimeData = csvread(CrimeFilename,1,0);
fclose(fid);

WeatherFilename = fullfile(Path,'Weather_All.csv');
fid = fopen(WeatherFilename);
tline = fgetl(fid);
WeatherField = regexp(tline, ',', 'split');
WeatherData = csvread(WeatherFilename,1,0);
fclose(fid);

% Predict the trend
Crime.Year = CrimeData(:,strcmpi(CrimeField,'Year'));
Crime.Month = CrimeData(:,strcmpi(CrimeField,'Month'));
Crime.Day = CrimeData(:,strcmpi(CrimeField,'Day'));
Crime.Holiday = CrimeData(:,strcmpi(CrimeField,'Holiday'));
Crime.DetrendRes = CrimeData(:,strcmpi(CrimeField,'DetrendRes'));
Crime.NumCrimes = CrimeData(:,strcmpi(CrimeField,'All'));

% find the range for detrending
Pred_datenum = datenum(TestDate.Year,TestDate.Month,TestDate.Day);
NyearDetrend = 2;
EstTrendSize = NyearDetrend*365;
Curr_datenum = Pred_datenum-2;
[CurrentDate.Year,CurrentDate.Month,CurrentDate.Day] = datevec(Curr_datenum);
TrendEnd= find(Crime.Year==CurrentDate.Year & Crime.Month==CurrentDate.Month & Crime.Day==CurrentDate.Day);
TrendStart = TrendEnd-EstTrendSize+1;

NumCrimes_temp = Crime.NumCrimes; % save daily total in a temporary variable T
% soomth out holidays in T
HolidayIndices = find(Crime.Holiday~=0);
for i = 1:length(HolidayIndices)
    if HolidayIndices(i)==1 %the first datum
        NumCrimes_temp(HolidayIndices(i)) = ...
            round(1/2*(NumCrimes_temp(HolidayIndices(i)+1)+NumCrimes_temp(HolidayIndices(i)+2)));
    elseif HolidayIndices(i)==length(Crime.Holiday) % the last datum
        NumCrimes_temp(HolidayIndices(i)) = ...
            round(1/2*(NumCrimes_temp(HolidayIndices(i)-1)+NumCrimes_temp(HolidayIndices(i)-2)));
    elseif i<length(HolidayIndices) && HolidayIndices(i+1)-HolidayIndices(i)==1 
        %holidays in weekend;observations on the nearest weekday
        NumCrimes_temp(HolidayIndices(i)) = ...
            round(1/2*(NumCrimes_temp(HolidayIndices(i)-1)+NumCrimes_temp(HolidayIndices(i)+2)));
    elseif i>1 && HolidayIndices(i)-HolidayIndices(i-1)==1
        NumCrimes_temp(HolidayIndices(i)) = ...
            round(1/2*(NumCrimes_temp(HolidayIndices(i)-2)+NumCrimes_temp(HolidayIndices(i)+1)));        
    else
        NumCrimes_temp(HolidayIndices(i)) = ...
            round(1/2*(NumCrimes_temp(HolidayIndices(i)-1)+NumCrimes_temp(HolidayIndices(i)+1)));
    end
end
% Fit the trend
Trend_hat = PredictTrend(NumCrimes_temp(TrendStart:TrendEnd));

% Pull training instances
NyearTrain = 9;
TrainWindowSize = NyearTrain*365;
TrainNeighborSize = 45;
TrainInstances1 = PullTrainInstances(CrimeData,CrimeField,TestDate,TrainWindowSize,TrainNeighborSize);
TrainInstances2 = PullTrainInstances(WeatherData,WeatherField,TestDate,TrainWindowSize,TrainNeighborSize);
TrainInstances = [TrainInstances1,TrainInstances2(:,4:end)];
Attributes = [CrimeField,WeatherField(4:end)];

% Pull testing variables
Weather.Year = WeatherData(:,strcmpi(WeatherField,'Year'));
if isempty(Weather.Year)
    Weather.Year = WeatherData(:,strcmpi(WeatherField,'"Year"'));
end
Weather.Month = WeatherData(:,strcmpi(WeatherField,'Month'));
if isempty(Weather.Month)
    Weather.Month = WeatherData(:,strcmpi(WeatherField,'"Month"'));
end
Weather.Day = WeatherData(:,strcmpi(WeatherField,'Day'));
if isempty(Weather.Day)
    Weather.Day = WeatherData(:,strcmpi(WeatherField,'"Day"'));
end

CurrDayIdx = find(Crime.Year==CurrentDate.Year & Crime.Month==CurrentDate.Month & Crime.Day==CurrentDate.Day);

WeatherPredictors.test = WeatherData(Weather.Year==TestDate.Year&Weather.Month==TestDate.Month&Weather.Day==TestDate.Day,4:end);

ResLag2 = Crime.DetrendRes(CurrDayIdx);
ResLag7 = Crime.DetrendRes(CurrDayIdx-5);
ResLag7Avg = mean([Crime.DetrendRes(CurrDayIdx-5),Crime.DetrendRes(CurrDayIdx-12),...
    Crime.DetrendRes(CurrDayIdx-19),Crime.DetrendRes(CurrDayIdx-26)]);
LaggedPredictors.test = [ResLag2,ResLag7,ResLag7Avg];

DOW_coded = dummyvar(1:7);
DOW_coded(:,1) = []; 
TemporalPredictors.test = DOW_coded(TestDate.DOW,:);
X.test = [TemporalPredictors.test,WeatherPredictors.test,LaggedPredictors.test];


DOW = TrainInstances(:,strcmpi(Attributes,'DayofWeek'));
DOW_coded = dummyvar(DOW);
DOW_coded(:,1) = []; 
TemporalPredictors.train = DOW_coded;

DOWName = {'DOW1','DOW2','DOW3','DOW4','DOW5','DOW6'};
LaggedVarName = {'ResLag2','ResLag7','ResLag7Avg'};
WeatherVarName = WeatherField(4:end);
VarName = [DOWName,WeatherField(4:end),LaggedVarName];

for k = 1:length(LaggedVarName)
    LaggedPredictors.train(:,k) = TrainInstances(:,strcmpi(LaggedVarName{k},Attributes));  
end
for k = 1:length(WeatherVarName)
    WeatherPredictors.train(:,k) = TrainInstances(:,strcmpi(WeatherVarName{k},Attributes));  
end

X.train_raw = [TemporalPredictors.train,WeatherPredictors.train,LaggedPredictors.train];
y.train_raw = TrainInstances(:,strcmpi('DetrendRes',Attributes));
X.train = X.train_raw;
y.train = y.train_raw;

% exclude holidays
HolidayIndicator = TrainInstances(:,strcmpi(Attributes,'Holiday'));   
X.train(HolidayIndicator~=0,:)= [];
y.train(HolidayIndicator~=0,:)= [];

DummyVar = DOWName;
DummyIdx = false(1,length(VarName));
for k = 1:length(DummyVar)
    DummyIdx = DummyIdx | strcmpi(VarName,DummyVar{k});
end