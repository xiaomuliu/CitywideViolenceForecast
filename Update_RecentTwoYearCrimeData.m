function [] = Update_RecentTwoYearCrimeData(Path) 

% download recent two year crime data
logintimeout('oracle.jdbc.driver.OracleDriver',10); %set timeout
conn = database('','IIT_USER','TSR1512','oracle.jdbc.driver.OracleDriver',...
    'jdbc:oracle:thin:@//167.165.243.151:1521/dwhracdb.dwhrac.chicagopolice.local');
if ~isempty(conn.message)
    err = MException('Update_RecentTwoYearCrimeData:Database_Connection_Error',conn.message);
    throw(err)
end
curs = runsqlscript(conn,fullfile(Path,'Recent_Two_Year_Update.sql'));
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

% Fit the trend
NumTrendEst = 730;
UpdateLength = N-NumTrendEst;
Trend_hat = zeros(UpdateLength,1);
for k = 1:UpdateLength
    Trend_hat(k) = PredictTrend(NumCrimes_temp(k:k+NumTrendEst-1));
end

% Lagged variables
DetrendRes = NumCrimes_temp(end-UpdateLength+1:end) - Trend_hat;
Buffer = 28;
LaggedVar = zeros(UpdateLength-Buffer,4);
for k = Buffer+1:UpdateLength
    ResLag1 = DetrendRes(k-1);
    ResLag2 = DetrendRes(k-2);
    ResLag7 = DetrendRes(k-7);
    ResLag7Avg = mean([DetrendRes(k-7),DetrendRes(k-14),DetrendRes(k-21),DetrendRes(k-28)]);
    LaggedVar(k-Buffer,:) = [ResLag1,ResLag2,ResLag7,ResLag7Avg];
end

% Truncate data and add back raw data of holidays
NumUpdate = UpdateLength-Buffer;
Year = Year(end-NumUpdate+1:end,:);
Month = Month(end-NumUpdate+1:end,:);
Day = Day(end-NumUpdate+1:end,:);
DOW = DOW(end-NumUpdate+1:end,:);
Holiday = Holiday(end-NumUpdate+1:end,:);

Trend_hat = Trend_hat(end-NumUpdate+1:end);
DetrendRes = DetrendRes(end-NumUpdate+1:end);
LaggedVar = LaggedVar(end-NumUpdate+1:end,:);
RawTarget = NumCrimes(end-NumUpdate+1:end);
DetrendRes(Holiday~=0) = RawTarget(Holiday~=0)-Trend_hat(Holiday~=0);

UpdateData = [Year,Month,Day,DOW,Holiday,LaggedVar,Trend_hat,DetrendRes,RawTarget];
% UpdateHeader = {'Year','Month','Day','DayofWeek','Holiday','ResLag1','ResLag2',...
%     'ResLag7','ResLag7Avg','Trend','DetrendRes','All'};

% Update and save the all-time crime dataset 
filename = fullfile(Path,'Crimes_All.csv');
fid = fopen(filename);
tline = fgetl(fid);
Header = regexp(tline, ',', 'split');
CrimeData = csvread(filename,1,0);
fclose(fid);

DateTab = CrimeData(:,1:3);
UpdateStart = find(UpdateData(1,1)==DateTab(:,1)&UpdateData(1,2)==DateTab(:,2)&UpdateData(1,3)==DateTab(:,3));
CrimeData(UpdateStart:end,:)=[];
CrimeData = [CrimeData;UpdateData];

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
