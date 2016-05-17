function [Trend_hat,TrendFit] = PredictTrend(NumCrimes)

p = 365.25;
modelfun = @(b,t)(b(1)+b(2)*t+b(3)*sin(2*pi*t/p)+b(4)*cos(2*pi*t/p));
opts = statset('nlinfit');
opts.RobustWgtFun = 'bisquare';
beta0 = [400;-0.05;1;1];

% Daily updated trend
t = (1:length(NumCrimes))';
beta = nlinfit(t,NumCrimes,modelfun,beta0,opts);
    
TrendFit = beta(1)+beta(2)*t+beta(3)*sin(2*pi*t/p)+beta(4)*cos(2*pi*t/p);          
Trend_hat = TrendFit(end);