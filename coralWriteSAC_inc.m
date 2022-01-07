function err = coralWriteSAC(filename,D);
% write data from coral format to a SAC file
% USAGE: err = coralWriteSAC(filename,D);
%
% WARNING:  This will overwrite existing files!
%
% D is a coral structure
% filename is either one filename or a cell array of N filenames 
% corresponding to the N seismograms
% If one file name is given and there are multiple seismograms
% file names are filename00001, filename00002, ...
% if file name ends in .sac or .SAC the numbers are put before .sac or .SAC
%
% see http://www.llnl.gov/sac/ -> Users Manual -> SAC Data File Format Parts 1&2
%
% written by Ken Creager   4-27-2007

err=0;
N=length(D);             % number of seismograms is coral structure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Make sure number of filenames match number of seismograms
%  Define filenames if necessary

if ~iscell(filename);    % if filename is not a cell array, make it a cell array
  filename={filename};
end

Nfile=length(filename);  % number of filenames

if N>1 & Nfile==1;       % if one filename and multiple seismograms, add numbers to filenames
  endsInSAC=findstr('.sac',lower(filename{1}));
  if length(endsInSAC)>0;
    endsInSAC=endsInSAC(end)
    if length(filename{1})-endsInSAC == 3;
      fileroot=filename{1}(1:endsInSAC-1);
      fileend =filename{1}(endsInSAC:end);
    end
  else
    fileroot=filename{1};
    fileend='';
  end
  for k=1:N;
    filename{k}=sprintf('%s%5d%s',fileroot,k,fileend);
    kblank=findstr(filename{k},' '); filename{k}(kblank)='0'; % change blanks to zeros
  end
end
Nfile=length(filename);  % update number of filenames

% if number of filenames does not match number of seismograms QUIT
if N~=Nfile
  disp(sprintf('ERROR in coralWriteSAC: number of seismograms:%d doesn''t match mumber of filenames:%d',N,Nfile));
  err=1;
  return
end


for k=1:N;  % loop over seismograms
  
  S=D(k);               % pick out one seismogram
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Convert coral seismogram start time to SAC reference time (NZ);
  refTime = S.recStartTime;   % reference time is time of first sample
  year    = refTime(1);
  month   = refTime(2);
  day     = refTime(3);
  jday    = datenum(year,month,day) - datenum(year,1,0); % julian day
  hour    = refTime(4);
  minute  = refTime(5);
  sec     = floor(refTime(6));                   % integer seconds
  msec    = round((refTime(6)-sec)*1000);        % miliseconds
  nz    = [year,jday,hour,minute, sec, msec]'; % seismogram start time
  
  
  % If the coral structure contains an earthquake origin time, set o to be time offset (s) from reference time
  o      = -12345;
  if isfield(S,'eqOriginTime')  % If the coral structure contains earthquake information then set these variables
    if length(S.eqOriginTime)==6;
      if S.eqOriginTime(1)>1900 & S.eqOriginTime(1)<2200;
        o      = timediff(D(k).eqOriginTime,refTime);  % earthquake origin time relative to refTime
      end
    end
  end
  
    
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % initialize and fill in numeric part of SAC header
  hdr     = zeros(110,1)-12345;% initialize SAC header with 110 default values

  hdr(1)  = S.recSampInt;     % DELTA; sample interval
  hdr(2)  = min(S.data);      % DEPMIN; minimum of data
  hdr(3)  = max(S.data);      % DEPMAX; maximum of data
  hdr(6)  = 0;                % B; start time of data relative to refTime (s)
  hdr(7)  = S.recSampInt*(S.recNumData-1); % E; end time of data relative to refTime (s)
  hdr(8)  = o;                % O; orgin time of earthquake relative to refTime
  
  % If the following fields exist in the coral structure and have one value and are real then add them to the SAC header            %SAC HEADER NAME
  kf=32; fld='staLat';    if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %STLA
  kf=33; fld='staLon';    if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %STLO
  kf=34; fld='staElev';   if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %STEL (m)
  kf=36; fld='eqLat';     if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %EVLA
  kf=37; fld='eqLon';     if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %EVLO
  kf=39; fld='eqDepth';   if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp*1000; end;end;end; %EVDP (m)
  kf=40; fld='eqMw';      if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;hdr(95)=55;end;end;end; %MAG; IMAGTYP='Mw'
  kf=51; fld='eqStaDist'; if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp*111.1;end;end;end; %DIST (km)
  kf=52; fld='staEqAzim'; if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %AZ
  kf=53; fld='eqStaAzim'; if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %BAZ
  kf=54; fld='eqStaDist'; if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %GCARC (deg)
  kf=58; fld='recAzimuth';if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;      end;end;end; %CMPAZM
  kf=59; fld='recDip';    if isfield(S,fld); tmp=getfield(S,fld); if length(tmp)==1; if isreal(tmp); hdr(kf)=tmp;   end;end;end; %CMPINC
    % CMPINC in sac is angle from vertical (0=up, 90=horiz, 180=down); dip in coral, AH and SEED is -90=up; 0=horiz, 90=down)  
  
  hdr(71:76) = nz;        % NZ; reference time 
  hdr(77)    = 6;         % NVHDR
  hdr(78)    = 0;         % NORID
  hdr(79)    = 0;         % NEVID
  hdr(80)    = S.recNumData; % NPTS
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

  s.kstnm(1:length(D(k).staCode))         = D(k).staCode;
  s.knetwk(1:length(D(k).staNetworkCode)) = D(k).staNetworkCode;
  s.kcmpnm(1:length(D(k).staChannel))     = D(k).staChannel;
  
  ichdr=1:8;
  chdr((01-1)*8+ichdr)   = s.kstnm;    %  1st character string block is station name
  chdr((21-1)*8+ichdr)   = s.kcmpnm;   % 21st character string block is channel name (e.g. 'BHZ')
  chdr((22-1)*8+ichdr)   = s.knetwk;   % 22nd character string block is Network Code (e.g. 'IU')

  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % open file, write SAC info, and close file
  fid = fopen(filename{k}, 'w');       % open SAC file
  fwrite(fid, hdr( 1:70), 'float');    % write float part of header 
  fwrite(fid, hdr(71:110), 'int');     % write integer part of header (includes logicals)
  fprintf(fid,chdr,'char');            % write character part of header
  fwrite(fid, S.data, 'float');        % write data
  fclose(fid);
 
end
