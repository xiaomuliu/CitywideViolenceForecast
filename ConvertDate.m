function [TestDate] = ConvertDate(InputDate)

DateVector = datevec(InputDate);
Year = DateVector(1);
Month = DateVector(2);
Day = DateVector(3);

DOW = weekday(InputDate);
DOW = DOW-1;
if DOW == 0;
    DOW = 7;
end

if (Month==12 && Day==31 && DOW==5)||(Month==1 && Day==2 && DOW==1)||(Month==1 && Day==1)
    Holiday = 1;
elseif Month==01 && Day>=15 && Day<=21 && DOW == 1 
     Holiday = 2;
elseif Month==02 && Day>=15 && Day<=21 && DOW == 1
     Holiday = 3;            
elseif Month==05 && Day>=25 && Day<=31 && DOW == 1 
     Holiday = 4;
elseif (Month==07 && Day==03 && DOW==5)||(Month==07 && Day==05 && DOW==1)||(Month==07 && Day==04)  
     Holiday = 5;
elseif Month==09 && Day>=1 && Day<=7 && DOW==1 
     Holiday = 6;
elseif Month==10 && Day>=8 && Day<=14 && DOW==1  
     Holiday = 7; 
elseif Month==10 && Day==31 
     Holiday = 8;
elseif (Month==11 && Day==10 && DOW==5)||(Month==11 && Day==12 && DOW==1)||(Month==11 && Day==11)  
     Holiday = 9;
elseif Month==11 && Day>=22 && Day<=28 && DOW==4 
     Holiday = 10;    
elseif (Month==12 && Day==24 && DOW==5)||(Month==12 && Day==26 && DOW==1)||(Month==12 && Day==25) 
     Holiday = 11;
else
    Holiday = 0;
end

TestDate.Year = Year;
TestDate.Month = Month;
TestDate.Day = Day;
TestDate.DOW = DOW;
TestDate.Holiday = Holiday;