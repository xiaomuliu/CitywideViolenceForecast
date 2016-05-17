function [] = Display_Results(InputDate,Prediction,Path)

fprintf('\nDate: %s\n', InputDate);
fprintf('Total Number of Violent Crimes:\n');
if datenum(InputDate)<today
    TestDate = ConvertDate(InputDate);
    ActualCount = Retrieve_Actual_Count(TestDate,Path);
    fprintf('Actual Count: %d\n',ActualCount);
end
fprintf('Predicted Count: %d\n', Prediction.value);
fprintf('Standard Error: %.2f\n', Prediction.SE);
fprintf('68%% Confidence Interval: %d+-%.2f\n', Prediction.value,Prediction.SE);
fprintf('95%% Confidence Interval: %d+-%.2f\n', Prediction.value,Prediction.CI);