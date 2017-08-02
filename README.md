# CitywideViolentCrimeForecast
This repository contatins Chicago citywide violent crime count predictive models implemented in MATLAB.

When distributing the program in new machines, please first run three scripts in folder DailyForecastToolConfig:
1. PredictTrend.m
2. Prepare_CrimeData.m
3. Prepare_WeatherData.m

Also make sure Oracle JDBC driver is properly configured in the local machine.

This program uses weather historical and forecast data provided by Weather Analytics (http://www.weatheranalytics.com/wa/). The request of accessing Weather Analytics’s data sets is done through its API by using the following URL format:

http://downloads.weatheranalytics.com/wawebdataservices/wawebservice/?ID=9D8C53D1-976B-4866-9AE5-C5A2C77EE7B0&LONG=-87.750&Lat=41.783&Req=davg&StartDate=dd/mm/yyyy&EndDate=dd/mm/yyyy&TS=LST&Format=csv&site=KMDW

The process of retrieving the weather historical and forecast data is already implemented in Update_WeatherData.m and the associated weather data is stored and updated in the file Weather_all.csv.

Pulling historical crime and weather data of several years every day would be a time-consuming process. To avoid doing that, both crime and weather data has been extracted and saved in Crimes_all.csv and Weather_all.csv, respectively. However, due to the unsteady data for the days close to the current day, updating the recent 60-day crime and 3-day weather data has to be done everyday. The weather data updating uses the procedure mentioned in the above paragraph by querying the weather data of past three days, current day and next three days. The returned data is stored in Seven_Day_Weather.csv temporarily, which later will be integrated in Weather_all.csv. The crime data updating is done via the script Recent_Two_Year_Update.sql, which returns the retrieved data to update Crimes_all.csv. All these processes have already been integrated in the automated program.

!!UPDATE: The service provided by Weather Analytics has been stopped. The Chicago Police Department(CPD) replaced it with its own source which is stored in schema WEATHER_DATA_FORMATTED. The weather data retrieval is done by Update_WeatherData3.m which interally calls SQL script Recent_Weather_Update.sql.



