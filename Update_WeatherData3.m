function [] = Update_WeatherData3(Path) 

% download the latest historical/forecast weather data
logintimeout('oracle.jdbc.driver.OracleDriver',10); %set timeout
conn = database('','IIT_USER','TSR1512','oracle.jdbc.driver.OracleDriver',...
    'jdbc:oracle:thin:@//167.165.243.151:1521/dwhracdb.dwhrac.chicagopolice.local');
if ~isempty(conn.message)
    err = MException('Update_WeatherData:Database_Connection_Error',conn.message);
    throw(err)
end
curs = runsqlscript(conn,fullfile(Path,'Recent_Weather_Update.sql'));
Data = curs.Data;
close(curs)
close(conn)

% UpdateData = [cellfun(@str2num,Data(:,1:3)),cell2mat(Data(:,4:end))]; 
UpdateData = cell2mat(Data);
% drop the last three columns (row numbers) and date column
UpdateData(:,end-2:end) = [];

% Update and save the all-time weather dataset 
filename = fullfile(Path,'Weather_All.csv');
fid = fopen(filename);
tline = fgetl(fid);
Header = regexp(tline, ',', 'split');
WeatherData = csvread(filename,1,0);
fclose(fid);

% Merge the new data
DateTab = WeatherData(:,1:3);
UpdateStart = find(UpdateData(1,1)==DateTab(:,1)&UpdateData(1,2)==DateTab(:,2)&UpdateData(1,3)==DateTab(:,3));
WeatherData(UpdateStart:end,:)=[];
WeatherData = [WeatherData;UpdateData];

% Calculate the difference
DailyValues = WeatherData(:,1:22);
WeatherDiff1 = DailyValues(2:end,4:end)-DailyValues(1:end-1,4:end);
WeatherDiff2 = DailyValues(3:end,4:end)-DailyValues(1:end-2,4:end);
% truncate the buffer
DailyValues(1:2,:)=[];
WeatherDiff1(1,:)=[];
CompleteValues = [DailyValues,WeatherDiff1,WeatherDiff2];
WeatherData(3:end,:) = CompleteValues;

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

dlmwrite(filename, WeatherData,'-append','delimiter',',');