function DT=timeadd(DT,t);
%   timeadd       add absolute date/times
% USAGE: DT=timeadd(DT,t);
%
% Function to add time (t) in (s) to an array of date/times
%
% Input parameters:
%      DT = (6xN) or (2xN) array of date/times in the format illustrated below.
%           If six rows they contain year, month, day, hour, minute, sec
%           If two rows they contain (year,month,day) (hour,minute,sec)
%           If years do not include century it is assumed to be the 20th, 
%           92 and 1992 are valid years 
%
%      t  = scalar or row vector (same length as DT) of times in (s)
%
% Output parameter:
%      DT = (6xN) (or (2xN) array of date/times, same as input array except the time t 
%           has been added to it. 
%     
%   Format of DT:
%
%   DT  =  [ YEAR1    YEAR2    ...  YEARN   |
%          | MONTH1   MONTH2   ...  MONTHN  |
%          | DAY1     DAY2     ...  DAYN    |
%          | HOUR1    HOUR2    ...  HOURN   |
%          | MINUTE1  MINUTE2  ...  MINUTEN |
%          | SECOND1  SECOND2  ...  SECONDN ]
%
%   or 
%
%   DT  =  [ DATE1    DATE2    ...  DATEN   | 
%          | TIME1    TIME2    ...  TIMEN   ]
%
%   where DATE=YYYY.MMDD; TIME = HHMMSS.SSSSSS;
%   eg. 1990.0321, 140623.0245  =  3/21/1990 14:06:23.0245
%
%
%
% This routine works by determining the maximum and minimum years of dates to process,
% setting a reference time as the beginning of the minimum year, and determining the
% time of all date/times in seconds with respect to the reference time. The time (t) is 
% added, and new date times are determined by reversing the above procedure.
% This routine keeps track of all leap days.
%
% K. Creager    2/4/92
%

secperday=24*60*60;
secperyear=365*secperday;
% construct a 2x13 table whos first column is for non-leap years and second is for leap
% years. The ith row is the julian day - 1 of the first day of the ith month
daytab=[31,28,31,30,31,30,31,31,30,31,30,31
        31,29,31,30,31,30,31,31,30,31,30,31];
daytab=[0,0;cumsum(daytab')]; daytab=reshape(daytab,1,26);

if length(DT)==0;  % no times were entered, return the empty matrix
  return
end

if length(DT(:,1))==2,
% date/time are entered in compressed format, convert to 6 vectors
  short_format='t';
  temp  =DT(1,:)+4000*eps;
  year  =floor(temp); temp=(temp-year)*100;
  month =floor(temp); temp=(temp-month)*100;
  day   =round(temp);
  temp  =DT(2,:)/10000+200*eps;
  hour  =floor(temp); temp=(temp-hour)*100;
  minute=floor(temp); 
  sec   =(temp-minute)*100;
else
  short_format='f';
  year=DT(1,:); month =DT(2,:); day=DT(3,:);      % convert date/time array to 6 vectors
  hour=DT(4,:); minute=DT(5,:); sec=DT(6,:);
end

n=length(year);                                 % n is number of date/times entered
if length(t)==1, t=t*ones(1,n); end             % convert time to be added to a vector

% If any of the dates/times or timeshifts are not finite, remove them for now and return them
% as NaN at the end
indFinite= find(isfinite(year+month+day+hour+minute+sec+t));
if length(indFinite)<n
  n     = length(indFinite);
  year  = year(indFinite);
  month = month(indFinite);
  day   = day(indFinite);
  hour  = hour(indFinite);
  minute= minute(indFinite);
  sec   = sec(indFinite);
  t     = t(indFinite);
end

yearflag=(year<1000);                           % flag years smaller than 1000
year=year+yearflag*1900;                        % add 1900 to years smaller than 1000
refyear=floor(min([year,year+t/secperyear]))-1; % define reference year
maxyear=floor(max([year,year+t/secperyear]))+1; % determine maximum year
y=refyear:maxyear;                              % reference vector of all possible years
                                    % 1 or 0 depending on whether this year is a leap year
yl= ( rem(y,4)==0 & ( rem(y,100)~=0 | rem(y,400)==0 ) );  
yl=[0 cumsum(yl)]; yl=yl(1:length(y));          %number of leap days occurring before year
yeartab=(y-refyear)*365 + yl;                   % day number at start of each year
yeardif=year-refyear;                           % number of years since reference year
yindex=yeardif+1;                               % array index for each year
leapdays=yl(yindex);                            %number of leap days occurring before year
                                                % leapyears = 1 if leap year, else = 0
leapyears= rem(year,4)==0 & ( rem(year,100)~=0 | rem(year,400)==0 );
                                                % days since reference year

% kluge to get around a matlab bug in version 4.1 When it is fixed the 
% if statements can be removed and just execute the days=... command

if all (size(month) == size(daytab))
  if all (month+leapyears*13 == ones(1,26))
    days=yeardif*365 + day-1;
  else
    days=yeardif*365+leapdays+daytab(month+leapyears*13)+day-1;
  end
else
  days=yeardif*365+leapdays+daytab(month+leapyears*13)+day-1;
end

time=days*secperday + hour*3600 + minute*60+sec;% time (s) since reference year


newtime=time+t;                                 % add time


days=floor(newtime/secperday);                  % days since reference year
time=newtime-days*secperday;                    % time (s) from start of day
hour=floor(time/3600);                          % hours
time=time-3600*hour;
minute=floor(time/60);                          % minutes
sec=time-minute*60;                             % seconds
for i=1:n; 
   yindex(i)=max(find(days(i)>=yeartab));        % get index for each year from days
end;
year=yindex-1+refyear;                          % year
days=days-yeartab(yindex);                      % julian day minus 1
                                                % years that are leap years have ones.
leapyears= rem(year,4)==0 & ( rem(year,100)~=0 | rem(year,400)==0 );
for i=1:n;                                      % get month and day from julian day
  month(i)=max(find(days(i)>=daytab([1:13]+leapyears(i)*13)));
end 
day=days-daytab(month+leapyears*13)+1;
year=year-yearflag*1900;                        % Put year back into original format

DT=DT+NaN;  % initialize output to be NaN
k=indFinite;
if short_format=='t';
% date/time were entered in compressed format, convert back to that format
  DT(1,k)=year+month/100+day/10000;
  DT(2,k)=hour*10000+minute*100+sec;
else
  DT(1,k)=year; DT(2,k)=month;  DT(3,k)=day;      % convert back to date/time array
  DT(4,k)=hour; DT(5,k)=minute; DT(6,k)=sec;
end


