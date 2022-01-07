function t=timediff(DT1,DT2);
%   timediff      subtract absolute date/times
% USAGE: t=timediff(DT1,DT2);
%
% Function to find differential times (s) of date/times.
%     If two arguments are given t = DT1-DT2 where DT1 and DT2 can be either
%     column vectors of date/times, or arrays of several date/times. There will be a value
%     of t for each column of DT1 and DT2. (DT1 and DT2 must be the same dimensions).
%     Alternatively, if DT2 is not given then the differential times are returned as a
%     vector of DT1 - DT1(:,1), ie differential times of all columns minus the first
%     column. Note that in this case t(1)=0.
%
% Input parameter:
%     DT1= (6xN) or (2xN) array of date/times in the format illustrated below.
%          the six rows contain year, month, day, hour, minute, sec
%          If years do not include century it is assumed to be the 20th, 
%          92 and 1992 are valid years. 
%     DT2= (6xN) or (2xN) is an optional array with the same format as DT1
%
%
% Output parameters:
%     t  = vector (same length as DT1) containing differential times (s)
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
 
if (nargin == 1),
   DT=DT1;
else
   DT=[DT1,DT2];
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

% If any of the dates/times or timeshifts are not finite, remove them for now and return them
% as NaN at the end
time0 = zeros(1,n)*NaN;
indFinite= find(isfinite(year+month+day+hour+minute+sec));
if length(indFinite)<n
  year  = year(indFinite);
  month = month(indFinite);
  day   = day(indFinite);
  hour  = hour(indFinite);
  minute= minute(indFinite);
  sec   = sec(indFinite);
end

yearflag=(year<1000);                           % flag years smaller than 1000
year=year+yearflag*1900;                        % add 1900 to years less than 1000
refyear=floor(min(year))-1;                     % define reference year
maxyear=floor(max(year))+1;                     % determine maximum year
y=refyear:maxyear;                              % reference vector of all possible years
                                    % 1 or 0 depending on whether this year is a leap year
yl= ( rem(y,4)==0 & ( rem(y,100)~=0 | rem(y,400)==0 ) );  
yl=[0 cumsum(yl)]; yl=yl(1:length(y));          %number of leap days occurring before year
yeartab=(y-refyear)*365 + yl;                   % day number at start of each year
yeardif=year-refyear;                           % number of years since reference year
yindex=yeardif+1;                               % array index for each year
leapdays=yl(yindex);                            %number of leap days occurring before year
                                                % leapyears = 1 if leap year, else = 0
leapyears=  rem(year,4)==0 & ( rem(year,100)~=0 | rem(year,400)==0 );
                                                % days since reference year
days=yeardif*365+leapdays+daytab(month+leapyears*13)+day-1;
time=days*secperday + hour*3600 + minute*60+sec;% time (s) since reference year

time0(indFinite) = time;

if (nargin == 1),
   t=time0-time0(1);
else
   t=time0(1:n/2)-time0(n/2+1:n);
end

