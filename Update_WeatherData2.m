function [] = Update_WeatherData2(Path)

% Update and save the all-time weather dataset 
filename = fullfile(Path,'Weather_All.csv');
fid = fopen(filename);
tline = fgetl(fid);
Header = regexp(tline, ',', 'split');
WeatherData = csvread(filename,1,0);
fclose(fid);

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