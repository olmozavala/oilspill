function CreateFile_csv(startDate,endDate,final_spill_day,barrels_spilled,barrels_collected,barrels_burned)
startDate         = [2010,11,01];
final_spill_day   = [2010,12,01];
endDate           = [2010,12,31];
barrels_spilled   = 100;
barrels_burned    = 10;
barrels_collected =  5;

firstDay          = datenum(startDate);
lastSpillDay      = datenum(final_spill_day);
lastDay           = datenum(endDate);
simDays           = firstDay:lastDay;
n_spillDays       = length(firstDay:lastSpillDay);
gregorianDates    = datevec(simDays);
MM                = gregorianDates(:,2);
DD                = gregorianDates(:,3);
YYYY              = gregorianDates(:,1);

Daily_barrels     = zeros(n_spillDays,1) + barrels_spilled;
Daily_barrels     = [Daily_barrels; zeros(length(lastSpillDay + 1 : lastDay),1)];
Daily_burned      = Daily_barrels*0 + barrels_burned;
Daily_collected   = Daily_barrels*0 + barrels_collected;
Others            = Daily_barrels*0;

full_array        = [MM,DD,YYYY,Daily_barrels,Daily_burned,Others,Daily_collected,Others];

dlmwrite('./data/datos_derrame.csv',full_array,'delimiter',';');
end