function HolidayPrediction = PredictHoliday(X,Model,DummyIdx,Scaling)
      
if strcmpi(Scaling,'zscore1') 
    [X.train(:,~DummyIdx), mu, sigma] = ZscoreScaling(X.train(:,~DummyIdx));
    X.holiday(:,~DummyIdx) = ZscoreScaling(X.holiday(:,~DummyIdx), mu, sigma);
elseif strcmpi(Scaling,'zscore2')
    [X.train, mu, sigma] = ZscoreScaling(X.train);
    X.holiday = ZscoreScaling(X.holiday, mu, sigma);
elseif strcmpi(Scaling,'minmax')
    [X.train(:,~DummyIdx), Xmax, Xmin] = MinMaxScaling(X.train(:,~DummyIdx));
    X.holiday(:,~DummyIdx) = MinMaxScaling(X.holiday(:,~DummyIdx), Xmax, Xmin);
end

X.holiday = x2fx(X.holiday,'linear');   
HolidayPrediction = X.holiday*Model.coeff';
                             
                             


