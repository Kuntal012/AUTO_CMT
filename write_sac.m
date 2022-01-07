function [] = write_sac (filepath, trace)
%
% write_sac is a heavily modified version of coralWriteSAC
% coralWriteSAC was written by Ken Creager   4-27-2007
% write_sac was written by Alex Mitchell 7-11-2012
%
% WARNING:  This will overwrite existing files!
%
% trace is a data structure made by irisFetch.m
% filepath is where the trace SAC file needs to be stored.
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert the trace start time to SAC times
refTime = datevec(trace.startTime);
year    = refTime(1);
month   = refTime(2);
day     = refTime(3);
jday    = datenum(year,month,day) - datenum(year,1,0); % julian day
hour    = refTime(4);
minute  = refTime(5);
sec     = floor(refTime(6));                   % integer seconds
msec    = round((refTime(6)-sec)*1000);        % miliseconds
nz      = [year,jday,hour,minute, sec, msec]'; % seismogram start time

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize and fill in numeric part of SAC header
hdr     = zeros(110,1)-12345;% initialize SAC header with 110 default values

hdr(1)  = 1 / trace.sampleRate;           % DELTA; sample interval
hdr(2)  = min(trace.data);                % DEPMIN; minimum of data
hdr(3)  = max(trace.data);                % DEPMAX; maximum of data
hdr(6)  = 0;                              % B; start time of data relative to seismogram start time.
hdr(7)  = hdr(1) * (trace.sampleCount-1); % E; end time of data relative to refTime (s)
hdr(8)  = -12345;                         % O; orgin time of earthquake relative to refTime

% If the following fields exist in the jrace structure and have one value and are real then add them to the SAC header            %SAC HEADER NAME
kf=32; fld='latitude';    if isfield(trace,fld); tmp=getfield(trace,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %STLA
kf=33; fld='longitude';    if isfield(trace,fld); tmp=getfield(trace,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %STLO
kf=34; fld='elevation';   if isfield(trace,fld); tmp=getfield(trace,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %STEL (m)
kf=35; fld='depth';   if isfield(trace,fld); tmp=getfield(trace,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %STDP (m)
kf=58; fld='azimuth';if isfield(trace,fld); tmp=getfield(trace,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %CMPAZM
kf=59; fld='dip';    if isfield(trace,fld); tmp=getfield(trace,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp+90;   end;end;end; %CMPINC
% CMPINC in sac is angle from vertical (0=up, 90=horiz, 180=down); 
% dip in coral, AH and SEED is -90=up; 0=horiz, 90=down)  
% irisFetch is the same format as coral.

hdr(71:76) = nz;        % NZ; reference time 
hdr(77)    = 6;         % NVHDR
hdr(78)    = 0;         % NORID
hdr(79)    = 0;         % NEVID
hdr(80)    = trace.sampleCount; % NPTS
hdr(86)    = 1;         % IFTYPE

hdr(106)   = 1;         % LEVEN
hdr(107)   = 1;         % LPSPOL
hdr(108)   = 1;         % LOVROK
hdr(109)   = 1;         % LCALDA

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize and fill in character part of SAC header
chdr = char(zeros(1,192)+32); % initialize SAC character header with 92 blanks
s.kstnm               = '        ';              % initialize station name 8 blanks
s.knetwk              = '        ';              % initialize network name 8 blanks
s.kcmpnm              = '        ';              % initialize channel name 8 blanks

s.kstnm(1:length(trace.station)) = trace.station;
s.knetwk(1:length(trace.network)) = trace.network;
s.kcmpnm(1:length(trace.channel)) = trace.channel;

ichdr=1:8;
chdr((01-1)*8+ichdr)   = s.kstnm;    %  1st character string block is station name
chdr((21-1)*8+ichdr)   = s.kcmpnm;   % 21st character string block is channel name (e.g. 'BHZ')
chdr((22-1)*8+ichdr)   = s.knetwk;   % 22nd character string block is Network Code (e.g. 'IU')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% open file, write SAC info, and close file
fid = fopen(filepath, 'w');       % open SAC file
fwrite(fid, hdr( 1:70), 'float');    % write float part of header 
fwrite(fid, hdr(71:110), 'int');     % write integer part of header (includes logicals)
fprintf(fid,chdr,'char');            % write character part of header
fwrite(fid, trace.data, 'float');    % write data
fclose(fid);
