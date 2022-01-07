function [day_of_year] = dyofyr(thedate)

% gives you the day of year
% example:
% doy = dyofyr([2010 8 16]);

yr = thedate(1);
month = thedate(2);
day = thedate(3);

previous_year = yr - 1;
year_start_num = datenum(previous_year, 12, 31);

day_num = datenum(yr,month,day);
day_of_year = day_num - year_start_num;