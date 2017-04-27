function serialDate = toSerialDate(year,julianDay, hour)
    % Converts a julian date to a serial date, to do this we need to know the year and hour to use 
    serialDate = datenum(year-1, 12, 31, hour, 0, 0) + julianDay;
