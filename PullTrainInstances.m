function [TrainInstances] = PullTrainInstances(Data,Field,TestDate,TrainWindowSize,TrainNeighborSize)

Year = Data(:,strcmpi(Field,'Year'));
if isempty(Year)
    Year = Data(:,strcmpi(Field,'"Year"'));
end
Month = Data(:,strcmpi(Field,'Month'));
if isempty(Month)
    Month = Data(:,strcmpi(Field,'"Month"'));
end
Day = Data(:,strcmpi(Field,'Day'));
if isempty(Day)
    Day = Data(:,strcmpi(Field,'"Day"'));
end

%*****************************
% $$leap year issus$$
if TestDate.Month==2 && TestDate.Day==29
    TestDate.Day = 28;
end
%*****************************

TrainDataStart = find(Year==TestDate.Year-floor(TrainWindowSize/365) & Month==TestDate.Month & Day==TestDate.Day)-TrainNeighborSize;
if TrainDataStart < 1
    %TrainDataStart = find(Year==TestDate.Year-floor(TrainWindowSize/365) & Month==TestDate.Month & Day==TestDate.Day);
    TrainDataStart = 1;
end
TrainDataEnd = TrainDataStart+TrainWindowSize-1; 

TrainDate = Month(TrainDataStart:TrainDataEnd)==TestDate.Month & Day(TrainDataStart:TrainDataEnd)==TestDate.Day;
NeighborIdx = TrainDate;

for j = 1:TrainWindowSize
    if TrainDate(j)==1
        if j-TrainNeighborSize <= 0
            NeighborIdx(1:j+TrainNeighborSize-1) = 1;
        elseif j+TrainNeighborSize-1 > TrainWindowSize
            NeighborIdx(j-TrainNeighborSize:end) = 1;
        else
            NeighborIdx(j-TrainNeighborSize : j+TrainNeighborSize-1) = 1;
        end
    end
end

TrainInstances = Data(TrainDataStart:TrainDataEnd,:);
TrainInstances = TrainInstances(NeighborIdx,:);
