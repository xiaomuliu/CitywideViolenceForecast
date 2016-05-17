function [] = Upload_Results2(PredVec,InputDate)
  
date_vec = datevec(InputDate);
year = num2str(date_vec(1));
month = num2str(date_vec(2));
day = num2str(date_vec(3));
timestamps = datestr(now,'yyyy-mm-dd HH:MM:SS'); 

logintimeout('oracle.jdbc.driver.OracleDriver',10); %set timeout
conn = database('','IIT_USER','TSR1512','oracle.jdbc.driver.OracleDriver',...
    'jdbc:oracle:thin:@//167.165.243.151:1521/dwhracdb.dwhrac.chicagopolice.local');
if ~isempty(conn.message)
    err = MException('Upload_Results:Database_Connection_Error',conn.message);
    throw(err)
end

Table = 'X_PRED_STAT3';
curs = exec(conn,['SELECT * FROM ',Table,' WHERE YEAR = ',...
    year,' AND MONTH = ', month,' AND DAY = ', day]);
curs = fetch(curs);

cols = {'YEAR','MONTH','DAY','RUN_TIME',...
        'PRED_M1','SE_M1','CI95L_M1','CI95U_M1',...
        'PRED_M2','SE_M2','CI95L_M2','CI95U_M2'};
val = {year,month,day,timestamps,...
        PredVec(1).value,PredVec(1).SE,PredVec(1).value-PredVec(1).CI,PredVec(1).value+PredVec(1).CI,...
        PredVec(2).value,PredVec(2).SE,PredVec(2).value-PredVec(2).CI,PredVec(2).value+PredVec(2).CI};
if strcmpi(curs.Data,'No Data')
    datainsert(conn, Table, cols, val);
else
    update(conn, Table, cols, val,{['WHERE YEAR = ',...
    year,' AND MONTH = ', month,' AND DAY = ', day]})   
end
exec(conn,'commit');   
close(conn)