function [Prediction] = DailyPrediction(Trend_hat,yhat,Correction)

% Total Prediction
Prediction.value = round(yhat.test+Trend_hat+Correction);
Prediction.SE = yhat.testSE;
Prediction.CI = yhat.testCI;
