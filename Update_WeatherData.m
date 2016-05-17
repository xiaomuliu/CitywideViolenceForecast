function [] = Update_WeatherData(InputDate,Path)

% % download weather data using weatheranalytics.com API
% startdate = datestr(datenum(InputDate)-6,'mm/dd/yyyy');
% enddate = datestr(datenum(InputDate)+2,'mm/dd/yyyy');
% url = ['http://data.weatheranalytics.com/wawebdataservices/wawebservice/?ID=9D8C53D1-976B-4866-9AE5-C5A2C77EE7B0&LONG=-87.750&Lat=41.783&Req=standard&StartDate=',...
%     startdate,'&EndDate=',enddate,'&TS=LST&Format=csv&site=KMDW'];
% trytimes = 5;
% count_r = 0;
% while count_r <= trytimes
%     [str,status_r] = urlread(url,'Timeout',20);
%     if status_r
%         break
%     else
%         count_r = count_r+1;
%     end
% end
% if count_r > trytimes
%     errmsg = 'Cannot read from weatheranalytics.com';
% %     fid = fopen(fullfile(Path,'errlog.txt'),'a+');
% %     fprintf(fid,'Time: %s\t error: %s\n\n',datestr(now),errmsg);
% %     fclose(fid);
% %     return
%     err = MException('Update_WeatherData:Weather_API_inaccessible',errmsg);
%     throw(err)
% else
%     parseStr = regexp(str,'.csv','split');
%     link1 = [parseStr{1},'.csv'];
%     filename = fullfile(Path,'Seven_Day_Weather.csv');
%     count_w = 0;
%     while count_w <= trytimes
%         [~,status_w] = urlwrite(link1,filename,'Timeout',20);
%         if status_w
%             break
%         else
%             count_w = count_w+1;
%         end
%     end
%     if count_w > trytimes
%         count_w2 = 0;
%         % try the alternative link
%         link2 = strrep(link1,'www.wxaglobal','downloads.weatheranalytics');
%         while count_w2 <= trytimes
%             [~,status_w] = urlwrite(link2,filename,'Timeout',20);
%             if status_w
%                 break
%             else
%                 count_w2 = count_w2+1;
%             end
%         end
%         if count_w2 > trytimes
%             errmsg = 'Cannot download files from weatheranalytics.com';
%     %         fid = fopen(fullfile(Path,'errlog.txt'),'a+');
%     %         fprintf(fid,'Time: %s\t error: %s\n\n',datestr(now),errmsg);
%     %         fclose(fid);
%     %         return
%             err = MException('Update_WeatherData:Weather_API_inaccessible',errmsg);
%             throw(err)
%         end
%     end
% end

% convert to daily data
fid = fopen(filename);
tline = fgetl(fid);
HourlyHeader = regexp(tline, ',', 'split');
HourlyHeader(1:4) = [];
ForecastData = csvread(filename,1,4);
Date = textscan(fid,'%s%s%s%s%*[^\n]','delimiter',',');
Date([1,2,4]) = [];
fclose(fid);

DateList = cellfun(@(x) datevec(datenum(x,'yyyy-mm-dd')), Date, 'UniformOutput', false);
DateList = cell2mat(DateList);
[DateList,~,dayidx] = unique(DateList(:,1:3),'rows');

HourlyFields = {'Tsfc_F','Tdew_F','Rh_PCT','CldCov_PCT','Tapp_F','PcpPrevHr_IN','Spd_MPH'};
N = size(ForecastData,1); 
P = length(HourlyFields);
HourlyValues = zeros(N,P);
for k = 1:P
    HourlyValues(:,k)= ForecastData(:,strcmpi(HourlyFields{k},HourlyHeader));
end

DailyFields = {'Year','Month','Day','avg_Tsfc_F','max_Tsfc_F','min_Tsfc_F','avg_Tdew_F',...
    'max_Tdew_F','min_Tdew_F','avg_Rh_PCT','max_Rh_PCT','min_Rh_PCT','avg_CldCov_PCT',...
    'max_CldCov_PCT','min_CldCov_PCT','avg_Tapp_F','max_Tapp_F','min_Tapp_F',...
    'tot_PcpPrevHr_IN','avg_Spd_MPH','max_Spd_MPH','min_Spd_MPH'};

%Daily average, max and min values
DailyValues = zeros(size(DateList,1),length(DailyFields));
for t = 1:size(DateList,1)
    Values = [];
    for k = 1:P
        if strcmpi(HourlyFields{k},'PcpPrevHr_IN')
            Dtot = sum(HourlyValues(dayidx==t,k));
            Values = [Values,Dtot];
        else
            Davg = mean(HourlyValues(dayidx==t,k));
            Dmax = max(HourlyValues(dayidx==t,k));
            Dmin = min(HourlyValues(dayidx==t,k));
            Values = [Values,Davg,Dmax,Dmin];
        end
    end
    DailyValues(t,:) = [DateList(t,:),Values];
end

% Integrate and calculate changes
WeatherDiff1 = DailyValues(2:end,4:end)-DailyValues(1:end-1,4:end);
WeatherDiff2 = DailyValues(3:end,4:end)-DailyValues(1:end-2,4:end);
% truncate the buffer
DailyValues(1:2,:)=[];
WeatherDiff1(1,:)=[];
CompleteValues = [DailyValues,WeatherDiff1,WeatherDiff2];

% KeepDate = datevec([now-1:now+1]);
KeepDate = datevec([datenum(InputDate)-1:datenum(InputDate)+1]);
KeepDate = KeepDate(1:3,:);
KeepIdx = false(size(DateList,1),1);
for k = 1:size(KeepDate,1)
    KeepIdx = KeepIdx | (KeepDate(k,1)==DateList(:,1)&KeepDate(k,2)==DateList(:,2)&KeepDate(k,3)==DateList(:,3));
end
KeepIdx(1:2,:)=[];  %remove the first two rows to match the "difference buffer removed" weather data
UpdateWeather = CompleteValues(KeepIdx,:);

% Update and save the all-time weather dataset 
filename = fullfile(Path,'Weather_All.csv');
fid = fopen(filename);
tline = fgetl(fid);
Header = regexp(tline, ',', 'split');
WeatherData = csvread(filename,1,0);
fclose(fid);

DateTab = WeatherData(:,1:3);
% UpdateStart = find(KeepDate(1,1)==DateTab(:,1)&KeepDate(1,2)==DateTab(:,2)&KeepDate(1,3)==DateTab(:,3));
% WeatherData(UpdateStart:end,:)=[];
% WeatherData = [WeatherData;UpdateWeather];
UpdateStart = find(KeepDate(1,1)==DateTab(:,1)&KeepDate(1,2)==DateTab(:,2)&KeepDate(1,3)==DateTab(:,3));
UpdateEnd = find(KeepDate(end,1)==DateTab(:,1)&KeepDate(end,2)==DateTab(:,2)&KeepDate(end,3)==DateTab(:,3));
if isempty(UpdateEnd)
    WeatherData(UpdateStart:end,:)=[];
    WeatherData = [WeatherData;UpdateWeather];
else
    WeatherData(UpdateStart:UpdateEnd,:)=UpdateWeather;
end


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

