function [] = Prepare_CrimeData(Path)

% download recent two year crime data
logintimeout('oracle.jdbc.driver.OracleDriver',10); %set timeout
conn = database('','IIT_USER','TSR1512','oracle.jdbc.driver.OracleDriver',...
    'jdbc:oracle:thin:@//167.165.243.151:1521/dwhracdb.dwhrac.chicagopolice.local');
if ~isempty(conn.message)
    err = MException('Prepare_CrimeData:Database_Connection_Error',conn.message);
    throw(err)
end
curs = runsqlscript(conn,fullfile(Path,'Pull_Crime_Data_01012001_to_Present.sql'));
Data = curs.Data;
close(curs)
close(conn)

Data = [cellfun(@str2num,Data(:,1:4)),cell2mat(Data(:,5:end))]; 
N = size(Data,1);
Year = Data(:,1);
Month = Data(:,2);
Day = Data(:,3);
DOW = Data(:,4);
Holiday = Data(:,5);
NumCrimes = Data(:,end);

NumCrimes_temp = NumCrimes; % save daily total in a temporary variable
% soomth out holidays in T
HolidayIndices = find(Holiday~=0);
for i = 1:length(HolidayIndices)
    if HolidayIndices(i)==1 %the first datum
        NumCrimes_temp(HolidayIndices(i)) = ...
            round(1/2*(NumCrimes_temp(HolidayIndices(i)+1)+NumCrimes_temp(HolidayIndices(i)+2)));
    elseif HolidayIndices(i)==N % the last datum
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

% Fit the trend (extend the beginning point)
NumTrendEst = 730;
DataLength = N-NumTrendEst;
Trendline = zeros(DataLength,1);
DetrendRes = zeros(size(Trendline));

for k = NumTrendEst+1:N
    Trendline(k-NumTrendEst) = PredictTrend(NumCrimes_temp(k-NumTrendEst:k-1));
    DetrendRes(k-NumTrendEst) = NumCrimes_temp(k)-Trendline(k-NumTrendEst);
end

% extend 28 days so that we can derived lagged variables for the first
% couples of instances
NumExtDay = 28;
[~,TrendFit] = PredictTrend(NumCrimes_temp(1:NumTrendEst));
Trendline_ext = TrendFit(end-NumExtDay+1:end);
DetrendRes_ext = NumCrimes_temp(NumTrendEst-NumExtDay+1:NumTrendEst) - Trendline_ext;
DetrendRes = [DetrendRes_ext;DetrendRes];

% Lagged variables
LaggedVar = zeros(DataLength,4);
for k = NumExtDay+1:NumExtDay+DataLength
    ResLag1 = DetrendRes(k-1);
    ResLag2 = DetrendRes(k-2);
    ResLag7 = DetrendRes(k-7);
    ResLag7Avg = mean([DetrendRes(k-7),DetrendRes(k-14),DetrendRes(k-21),DetrendRes(k-28)]);
    LaggedVar(k-NumExtDay,:) = [ResLag1,ResLag2,ResLag7,ResLag7Avg];
end

% Truncate year 2001,2002 and add back raw data of holidays
TruncateIdx = Year==2001|Year==2002;
Year = Year(~TruncateIdx);
Month = Month(~TruncateIdx);
Day = Day(~TruncateIdx);
DOW = DOW(~TruncateIdx);
Holiday = Holiday(~TruncateIdx);
DetrendRes = DetrendRes(NumExtDay+1:end);

RawTarget = NumCrimes(~TruncateIdx);
DetrendRes(Holiday~=0) = RawTarget(Holiday~=0)-Trendline(Holiday~=0);

% save as a csv file
Header = {'Year','Month','Day','DayofWeek','Holiday','ResLag1','ResLag2','ResLag7','ResLag7Avg','Trend','DetrendRes','All'};
CrimeData = [Year,Month,Day,DOW,Holiday,LaggedVar,Trendline,DetrendRes,RawTarget];
% CrimeDataset = mat2dataset(Data,'VarNames',Header);
% export(CrimeDataset,'File',fullfile(Path,'Crime_All.csv'),'Delimiter',',');

filename = fullfile(Path,'Crimes_All.csv');
fid = fopen(filename,'w');
hcol = size(Header,2);
for idx = 1:hcol
    fprintf (fid, '%s', Header{idx});
    if idx ~= hcol
        fprintf (fid, ',');
    else
        fprintf (fid, '\n' );
    end
end
fclose(fid);

dlmwrite(filename, CrimeData,'-append','delimiter',',');