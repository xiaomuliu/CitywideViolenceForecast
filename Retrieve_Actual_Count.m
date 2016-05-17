function [ActualCount] = Retrieve_Actual_Count(TestDate,Path)

CrimeFilename = fullfile(Path,'Crimes_All.csv');
fid = fopen(CrimeFilename);
tline = fgetl(fid);
CrimeField = regexp(tline, ',', 'split');
CrimeData = csvread(CrimeFilename,1,0);
fclose(fid);

Crime.Year = CrimeData(:,strcmpi(CrimeField,'Year'));
Crime.Month = CrimeData(:,strcmpi(CrimeField,'Month'));
Crime.Day = CrimeData(:,strcmpi(CrimeField,'Day'));
ActualCount = CrimeData(Crime.Year==TestDate.Year & Crime.Month==TestDate.Month & Crime.Day==TestDate.Day,...
    strcmpi(CrimeField,'All'));
    
 