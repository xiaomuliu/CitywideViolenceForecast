function [] = Prepare_WeatherData(Path)

% historical daily data
file_historical = fullfile(Path,'KMDW_DAILIES_2003-01-01_2014-06-25_hist.csv');

fid = fopen(file_historical);
tline = fgetl(fid);
DailyHeader = regexp(tline, ',', 'split');
DailyHeader(1:2) = [];
HistoricalData = csvread(file_historical, 1, 2);
fclose(fid);

DailyFields = {'Year','Month','Day','avg_Tsfc_F','max_Tsfc_F','min_Tsfc_F','avg_Tdew_F',...
    'max_Tdew_F','min_Tdew_F','avg_Rh_PCT','max_Rh_PCT','min_Rh_PCT','avg_CldCov_PCT',...
    'max_CldCov_PCT','min_CldCov_PCT','avg_Tapp_F','max_Tapp_F','min_Tapp_F',...
    'tot_PcpPrevHr_IN','avg_Spd_MPH','max_Spd_MPH','min_Spd_MPH'};
N = size(HistoricalData,1); 
P = length(DailyFields);
DailyValues1 = zeros(N,P);
for k = 1:P
    DailyValues1(:,k)= HistoricalData(:,strcmpi(DailyFields{k},DailyHeader));
end

% Buffer data
file_buffer = fullfile(Path,'KMDW_HOURLY_2002_12_30_2002_12_31.csv');

fid = fopen(file_buffer);
tline = fgetl(fid);
HourlyHeader = regexp(tline, ',', 'split');
HourlyHeader(1:4) = [];
BuffData = csvread(file_buffer,1,4);
Date = textscan(fid,'%s%s%s%s%*[^\n]','delimiter',',');
Date([1,2,4]) = [];
fclose(fid);

DateList = cellfun(@(x) datevec(datenum(x,'yyyy-mm-dd')), Date, 'UniformOutput', false);
DateList = cell2mat(DateList);
[DateList,~,dayidx] = unique(DateList(:,1:3),'rows');

HourlyFields = {'Tsfc_F','Tdew_F','Rh_PCT','CldCov_PCT','Tapp_F','PcpPrevHr_IN','Spd_MPH'};
N = size(BuffData,1); 
P = length(HourlyFields);
HourlyValues = zeros(N,P);
for k = 1:P
    HourlyValues(:,k)= BuffData(:,strcmpi(HourlyFields{k},HourlyHeader));
end

%Daily average, max and min values
DailyValues2 = zeros(size(DateList,1),length(DailyFields));
for t = 1:size(DateList,1)
    BuffValues = [];
    for k = 1:P
        if strcmpi(HourlyFields{k},'PcpPrevHr_IN')
            Dtot = sum(HourlyValues(dayidx==t,k));
            BuffValues = [BuffValues,Dtot];
        else
            Davg = mean(HourlyValues(dayidx==t,k));
            Dmax = max(HourlyValues(dayidx==t,k));
            Dmin = min(HourlyValues(dayidx==t,k));
            BuffValues = [BuffValues,Davg,Dmax,Dmin];
        end
    end
    DailyValues2(t,:) = [DateList(t,:),BuffValues];
end

% Gap data(between the last entry in the historical dataset and the current day data)
startdate = '06/26/2014';
enddate = datestr(today,'mm/dd/yyyy');
url = ['http://data.weatheranalytics.com/wawebdataservices/wawebservice/?ID=9D8C53D1-976B-4866-9AE5-C5A2C77EE7B0&LONG=-87.750&Lat=41.783&Req=standard&StartDate=',...
    startdate,'&EndDate=',enddate,'&TS=LST&Format=csv&site=KMDW'];
str = urlread(url);
parseStr = regexp(str,'.csv','split');
link = [parseStr{1},'.csv'];
file_gap = fullfile(Path,'KMDW_HOURLY_2014_06_26_present.csv');
urlwrite(link,file_gap);

fid = fopen(file_gap);
tline = fgetl(fid);
HourlyHeader = regexp(tline, ',', 'split');
HourlyHeader(1:4) = [];
GapData = csvread(file_gap,1,4);
Date = textscan(fid,'%s%s%s%s%*[^\n]','delimiter',',');
Date([1,2,4]) = [];
fclose(fid);

DateList = cellfun(@(x) datevec(datenum(x,'yyyy-mm-dd')), Date, 'UniformOutput', false);
DateList = cell2mat(DateList);
[DateList,~,dayidx] = unique(DateList(:,1:3),'rows');

HourlyFields = {'Tsfc_F','Tdew_F','Rh_PCT','CldCov_PCT','Tapp_F','PcpPrevHr_IN','Spd_MPH'};
N = size(GapData,1); 
P = length(HourlyFields);
HourlyValues = zeros(N,P);
for k = 1:P
    HourlyValues(:,k)= GapData(:,strcmpi(HourlyFields{k},HourlyHeader));
end

%Daily average, max and min values
DailyValues3 = zeros(size(DateList,1),length(DailyFields));
for t = 1:size(DateList,1)
    GapValues = [];
    for k = 1:P
        if strcmpi(HourlyFields{k},'PcpPrevHr_IN')
            Dtot = sum(HourlyValues(dayidx==t,k));
            GapValues = [GapValues,Dtot];
        else
            Davg = mean(HourlyValues(dayidx==t,k));
            Dmax = max(HourlyValues(dayidx==t,k));
            Dmin = min(HourlyValues(dayidx==t,k));
            GapValues = [GapValues,Davg,Dmax,Dmin];
        end
    end
    DailyValues3(t,:) = [DateList(t,:),GapValues];
end
% Integrate and calculate changes
DailyValues = [DailyValues2;DailyValues1;DailyValues3];
WeatherDiff1 = DailyValues(2:end,4:end)-DailyValues(1:end-1,4:end);
WeatherDiff2 = DailyValues(3:end,4:end)-DailyValues(1:end-2,4:end);
% truncate the buffer
DailyValues(1:2,:)=[];
WeatherDiff1(1,:)=[];
CompleteValues = [DailyValues,WeatherDiff1,WeatherDiff2];
% complete fields
for k = 4:length(DailyFields)
    Fields_Diff1{k-3} = [DailyFields{k},'_Diff1'];
    Fields_Diff2{k-3} = [DailyFields{k},'_Diff2'];
end
CompleteFields = [DailyFields,Fields_Diff1,Fields_Diff2];

%save as a csv file
% HistWeatherDataset = mat2dataset(CompleteValues,'VarNames',CompleteFields);
% export(HistWeatherDataset,'File',fullfile(Path,'Weather_All.csv'),'Delimiter',',');

filename = fullfile(Path,'Weather_All.csv');
fid = fopen(filename,'w');
hcol = size(CompleteFields,2);
for idx = 1:hcol
    fprintf (fid, '%s', CompleteFields{idx});
    if idx ~= hcol
        fprintf (fid, ',');
    else
        fprintf (fid, '\n' );
    end
end
fclose(fid);

dlmwrite(filename, CompleteValues,'-append','delimiter',',');