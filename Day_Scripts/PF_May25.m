close all
clearvars
tic
addpath(genpath('/rhome/kchau012/bigdata/Cholame/home/'));
% working Directory
parent_Dir='/rhome/kchau012/bigdata/Parkfield_VLFE/CMT/';
for hrrr=0:23
clearvars -except hrrr parent_Dir
date_start=25
try
    
comEval(strcat("cd ",parent_Dir));
%% Load Stations list
sta=importdata('Stations_LST.txt');

for i=1:length(sta.data)
s_dist(i).lat=sta.data(i,1);
s_dist(i).lon=sta.data(i,2);
s_dist(i).net=sta.textdata(i,1);
s_dist(i).nam=sta.textdata(i,2);
s_dist(i).dist=nan;
end

%% Grid Parameters
lat_s=35.5;       % Latitude South
lat_n=36.0;       % Latitude North
lon_w=-120.4;     % Longitude West
lon_e=-120.2;     % Longitude East
g_space=0.2;    % Grid Spacing
lat=lat_s:g_space:lat_n;
lon=lon_w:g_space:lon_e;
s_lt=length(lat);
s_ln=length(lon);
% Making Grid for the area
[LON,LAT]=meshgrid(lon,lat);

%% Time window
s_time=[2011 07 27 00 00 00];
e_time=[2011 07 27 23 00 00];
year=2014;
month=05;
start_day=date_start;
end_day=date_start;
start_hour=hrrr;
end_hour=hrrr+1;

%% Finding the closest stations for every grid point
MF=0;% Do match filtering 1:Yes 0:NO
Comb_Stns=3;%select number of stations to be used or making combinations

c_grid=1; % Grid Index
for Lat_loop=1:s_lt
    for Lon_loop=1:s_ln
        % Grid Index

        grd_n=c_grid;
        g_fold=strcat('GP_',num2str(grd_n));
        gp=[lat(Lat_loop) lon(Lon_loop)];
        for st_loop=1:length(sta.data)
            st_coor=[s_dist(st_loop).lat s_dist(st_loop).lon];
            s_dist(st_loop).dist=lldistkm(st_coor,gp);
            s_dist(st_loop).azim=azimuth(gp,st_coor);
        end
        af=fieldnames(s_dist);
        ac=struct2cell(s_dist);
        sz=size(ac);
        ac=reshape(ac,sz(1),[]);
        ac=ac';
        ac=sortrows(ac,5);
        ac=reshape(ac',sz);
        ASorted=cell2struct(ac,af,1);
        %% Sorting the stations based on coordinates
        % For quadrant 1
        s_azim(:,1)=[ASorted.azim]';s_azim(:,2)=[ASorted.dist]';
        quad1=find(s_azim(:,1)>0 & s_azim(:,1)<90 & s_azim(:,2) > 10);
        quad2=find(s_azim(:,1)>90 & s_azim(:,1)<180 & s_azim(:,2) > 10);
        quad3=find(s_azim(:,1)>180 & s_azim(:,1)<270 & s_azim(:,2) > 10);
        quad4=find(s_azim(:,1)>270 & s_azim(:,1)<360 & s_azim(:,2) > 10);
        q_count=1;q1=1;q2=1;q3=1;q4=1;
        while q_count<=6 %|| q1+q2+q3+q4 ~=5
           if isempty(quad1) == 0 && q1 <= size(quad1,1) && q_count <=5
              s_Closest(q_count,:)=ASorted(quad1(q1));q1=q1+1; q_count=q_count+1;
           end 
           if isempty(quad2) == 0 && q2 <= size(quad2,1) && q_count <=5
              s_Closest(q_count,:)=ASorted(quad2(q2));q2=q2+1; q_count=q_count+1;
           end
           if isempty(quad3) == 0 && q3 <= size(quad3,1) && q_count <=5
              s_Closest(q_count,:)=ASorted(quad3(q3));q3=q3+1; q_count=q_count+1;
           end
           if isempty(quad4) == 0 && q4 <= size(quad4,1) && q_count <=5
              s_Closest(q_count,:)=ASorted(quad4(q4));q4=q4+1; q_count=q_count+1;
           end
           if q_count == 6
               q_count=q_count+1;
           end
        end
%         s_Closest=ASorted(1:5);
        p=[s_Closest(:).nam];
        C=nchoosek(p,Comb_Stns); % Creating combination of 3 stations from the 5 nearest station
        
        %% Creating folder for storing paramer files
        par_folNam=strcat(num2str(year),num2str(month),num2str(start_day),'_',num2str(start_hour),'_',num2str(end_hour));
        comEval(strcat('mkdir Param_AD/',par_folNam))
        comEval(strcat("cd ",parent_Dir,'Param_AD/',par_folNam));
        
        %% Create The parameter file for running moment tensor
        fid=fopen('grid_inv_ah.prm','w');
        fprintf(fid,'LON %3.1f,%3.1f\n',gp(2)-0.3,gp(2)+0.3);
        fprintf(fid,'LAT %3.1f,%3.1f\n',gp(1)-0.3,gp(1)+0.3);
        fprintf(fid,'DDEG %1.1f \n',g_space);
        fprintf(fid,'DTIME 1 \n');
        fprintf(fid,'MAXTIME 3400 \n');
        fprintf(fid,'DEPTH 20,25,30,35,40 \n');
        fprintf(fid,'BTIME 94 \n');
        fprintf(fid,'TWIND 90 \n');
        fprintf(fid,'GFPATH /rhome/kchau012/bigdata/Taiwan_New/GF_Taiwan_3/ \n');
        fclose(fid);
        comEval(strcat("cd ",parent_Dir));
        %% Running moment tensor inversion for every combination
        pdir = strcat(parent_Dir,'MTI/'); % where the codes reside
        prmfile = strcat(parent_Dir,'Param_AD/',par_folNam,'/grid_inv_ah.prm');
        %prmfile = '/rhome/kchau012/bigdata/Data_Ridgecrest/CMT_Ridgecrest/grid_inv_ah.prm'; % parameter file
        eval(strcat("mkdir ",parent_Dir,'Output'));
        [rit,cl]=size(C);
        for comb_loop=1:rit
                comb(:)=C(comb_loop,:);
                for ikll=start_day:end_day

                    try
                    %% 
                    fntn = '7D';
                    d_pwd = parent_Dir;
                    s_hour = [year month ikll start_hour];
                    e_hour = [year month ikll end_hour];
                    outdir = strcat(parent_Dir,'Output/'); % outputs of MTI
                    % raw data from IRIS ORIGINAL
                    datae =strcat(parent_Dir,'OData/');
                    % Cleaned up data
                    cdfn=strcat(num2str(year),num2str(month),num2str(start_day),num2str(start_hour));
                    CLEAN_dir=strcat(parent_Dir,'Clean_Data/',cdfn,'/');
                    comEval(strcat('mkdir'," ",CLEAN_dir));
                    datac = CLEAN_dir;CLEAN_dir='';
                    
                    %datac = '/rhome/kchau012/bigdata/Data_Ridgecrest/CMT_Ridgecrest/Clean_Data/';
                    
                    nhour = round((datenum([e_hour 0 0]) - datenum([s_hour 0 0]))*24); % numbers of hours
                    if exist(datac, 'dir') ~= 7
                        eval(['mkdir ' datac])
                    end


                    for ihr = 1: nhour
                        thedtn = datenum([s_hour 0 0]) + ((ihr-1)/24);
                        thedtv = datevec(thedtn);
                        thedtstr1 = datestr(thedtn, 'yyyy-mm-dd-HH');
                        thedtstr2 = datestr(thedtn, 'yy-mmmm');
                        str_sep1 = textscan(thedtstr1, '%s %s %s %s', 'delimiter', '-');
                        str_sep2 = textscan(thedtstr2, '%s %s', 'delimiter', '-');
                        datadh = [datae str_sep2{1,2}{1} str_sep2{1,1}{1} '/' str_sep1{1,1}{1} str_sep1{1,2}{1} str_sep1{1,3}{1} '/' str_sep1{1,4}{1} '/'];
                        outdirh = [outdir str_sep2{1,2}{1} str_sep2{1,1}{1} '/' str_sep1{1,1}{1} str_sep1{1,2}{1} str_sep1{1,3}{1} '/' str_sep1{1,4}{1}];
                        
                        datakk=datadh;
                        ppk1=[parent_Dir,'Data/' str_sep2{1,2}{1} str_sep2{1,1}{1} '/' str_sep1{1,1}{1} str_sep1{1,2}{1} str_sep1{1,3}{1} '/' str_sep1{1,4}{1} '/'];
%                         if ~exist(dfold, 'ppk1')
%                             % Folder does not exist so create it.
%                             mkdir(ppk1);
%                         end
                        eval(['mkdir ' ppk1]);
                        comEval(strcat("cd ",parent_Dir,'Param_AD/',par_folNam));
                       
                        pth=fopen('pathway','w');
                        eval(['!rm ' ppk1 '*.SAC']);
                        cbf='';
                        for sacll=1:Comb_Stns

                            %p=(extractBetween(comb{sacll},1,4));
                            %p=p{:};
                            p=comb{sacll};
                            if sacll==1
                                fprintf(pth,'cp %s*%s*.SAC %s\n',datadh,p,ppk1);
                                cbf=strcat(cbf,p);
                            else
                                fprintf(pth,'cp %s*%s*.SAC %s\n',datadh,p,ppk1);
                                cbf=strcat(cbf,'_',p);
                            end
                            
                        end
                        fprintf(pth,'cp -r %szp %s',datadh,ppk1);
                        fclose(pth);
                        eval('!sh pathway');
                        comEval(strcat("cd ",parent_Dir));
                        datadh=ppk1;
                        % make output directory
                        eval(['mkdir ' outdirh]);
                        % Get the data
                        % remove all sac and zp files
                        eval(['!rm -r ' datac '*']);
                        % copy the files for the directory
                        copy_data(datadh, datac, '-v');
                        % Common beginnings of the filenames
                        filehd = sprintf('%s.%03i.%s.00.0000.%s.', str_sep1{1,1}{1}, dyofyr(thedtv(1:3)), str_sep1{1,4}{1}, fntn);
                        % filehd='2010.046.22.00.0000.TW.';
                        % Make saclist
                        eval (strcat("cd ",datac));
                        eval (['!ls ' filehd '*.SAC > sac.list']);
                        no_stn=length(dir('*HZ*'));
                        
%                       
%                         for sacll=1:3
% 
%                             p=(extractBetween(comb{sacll},1,4));
%                             p=p{:};
%                             if sacll==1
%                                 eval (['!ls *' p '*.SAC > sac.list'])
%                             else
%                                 eval (['!ls *' p '*.SAC >> sac.list'])
%                             end
%                         end
                        % Go to the output directory from where MTI code will be run and output will be saved
                        eval(['cd ' outdirh])
                        eval(['!rm ./*' ])
                        if no_stn == 3
                        eval(['!cp ' prmfile ' .'])
                        % Make station-channel list
                        eval(['!' pdir 'perl/make_cmt_list_ah.pl ' datac 'sac.list > cmt_stat.list'])   
                        % Remove instrument response and filter
                        eval(['!' pdir 'perl/bat_sac_deconv_ah.pl ' filehd ' ./cmt_stat.list ' datac])  
                        % Make station list with coordinates
                        eval(['!cp ' d_pwd '/make_sta_list.m .'])
                        make_sta_list (datac, './station.list')
                        % check data
                        eval(['cd ' d_pwd])
                        % check_data (datac, filehd) %runs check_data.m
                        % Remake saclist
                        eval (['cd ' datac])
                        eval (['!mv ./sac.list ./old_sac.list '])
                        eval (['!ls ' filehd '*.SAC > sac.list'])
                        % Remake station-channel list
                        eval(['cd ' outdirh])
                        eval(['!mv ./cmt_stat.list ./old_cmt_stat.list'])
                        eval(['!' pdir 'perl/make_cmt_list_ah.pl ' datac 'sac.list > cmt_stat.list'])
                        % Remake station list with coordinates
                        eval(['!mv ./station.list ./old_station.list'])
                        make_sta_list (datac, './station.list')
                        delete './make_sta_list.m'
                        % Run moment tensor inversion code
                      eval(['!' pdir 'perl/exe_grid_tdmrf_ah_forML3.pl ' filehd ' ./grid_inv_ah.prm ' str_sep1{1,1}{1} ' ' str_sep1{1,2}{1} ' '  str_sep1{1,3}{1} ' ' str_sep1{1,4}{1} ' 00 ' datac])
                        % Get the source parameters corresponding to the highest VR
                        eval(['!sort -k 11,11n grid_tdmrf_inv.out | tail -n 1 > event_hypoinfo.list'])
                        % Use GMT to plot results
                        eval(['!' pdir 'perl/prep_gmt_draw_ah_forML3.pl ' filehd ' ' datac])
                        eval(['!ps2raster -A -Tf plot_01.ps'])
                        % Copy stuff
                        eval(['!mv ' datac 'sac.list .']);
                        fold_name=strcat(['C' num2str(comb_loop) cbf]); 
                        eval(['!mkdir ' fold_name]);
                        eval(['!rm grid_tdmrf_inv.out']);
                        eval(['!cp * ./' fold_name]);
                        eval(['!rm *']);
                        end
                        %clear thedtn thedtv datadh datadh thedtstr2 thedtstr1 str_sep1 str_sep2 datadh outdirh filehd
                        %eval(['cd ' d_pwd])
                        if comb_loop==rit
                           eval(['!mkdir ' g_fold]);
                           eval(['!mv C* ' g_fold]);
                        end
                        kid=eval('pwd');
                        comeval(strcat("cd ",parent_Dir));                 
                    end              

                    catch 
                    end
                end
                
        end
        c_grid=c_grid+1;
        comEval(strcat("cd ",parent_Dir));
    end
end
        %% Gathering Best results
        eval(['cd ' kid '/']);
        % gather_result.sh removes any results that is showing negative
        % V.R.
        comEval(strcat("!cp ",parent_Dir,'gather_results_3stns.sh ./'));
        %clear all
        eval(['!sh gather_results_3stns.sh|tail -n +2 |sort -k 13,13nr > BestResults.txt']);
        BR=importdata('BestResults.txt');
        
        fidi = fopen('BestResults.txt');
        if all(fgetl(fidi) ~= -1)
        
        AA=BR.textdata(:,9:10);
        for i=1:size(AA,1)
            kk(i,1)=str2double(AA{i,1});kk(i,2)=str2double(AA{i,2});
        end
        BZ=[kk BR.data(:,2:6)];
        [U,ux,uy]=unique(BZ(:,1:2),'rows');U=BZ(ux,:);p=std(U(:,5:7)');
        BZ=[U p']; 
        UF=[BR.textdata(ux(:),1:8) BR.textdata(ux(:),11)];
        % Getting stations combinations
        id_ev=find(p(:)<10);
        if isempty(id_ev) == 0
        cc_ev=1;
        for i=1:length(id_ev)
            
            s(cc_ev,:)=[strsplit(UF{id_ev(i),2},'_')];
            c(cc_ev)=extractBefore(s(id_ev(i),1),3);
            s(cc_ev,1)=extractAfter(s(id_ev(i),1),2);cc_ev=cc_ev+1;
            
        end
         UF=[UF(:,1) c' s(:,1:4) UF(:,3:9)];
         save Results.mat UF U ux uy
         fold_name='Best_result'; 
        eval(['!mkdir ' fold_name]);
        eval(['!cp * ./' fold_name]);
         clearvars -except hrrr date_start parent_Dir
         %% Returning the Best Resultsload Results.mat
         % Getting only the results where V.R. is greater than CLVD
         load ./Best_result/Results.mat
         indx=find(U(:,3)>U(:,4));
         UF=UF(indx,:);U=U(indx,:);
         
         eval(strcat("!cp ",parent_Dir,'lldistkm.m ./'));
         % Selecting results with event points atleast 1.5 degrees apart
         kk=U(:,1:2);
         for loop_evt=1:size(kk,1)
            for loop_evt2=1:size(kk,1)
                dist_evt(loop_evt,loop_evt2)=lldistkm(kk(loop_evt,:),kk(loop_evt2,:));
            end
         end
         
         for le=1:size(kk,1)
            ex=find(dist_evt(le,:)<50);% & dist_evt(le,:)~=0);
            ep=find(max(U(ex(:),3)));
            num_of_evt(le)=ex(ep);
            for le2=1:length(ex)
                if le2 ==1 && length(ex) ~= 1
                    fprintf('%d\t%d\t',le,ex(le2));
                elseif le2 ~= length(ex) && le2 ~=1
                    fprintf('%d\t',ex(le2));
                elseif le2 == 1 && length(ex) == 1
                    fprintf('%d\t%d\n',le,ex(le2));
                else
                    fprintf('%d\n',ex(le2));
                end
            end      
         
         end
        end
        % Final Distinct events distributed in time and selected based on
        % maximum variance reduction are
        if exist('num_of_evt','var') == 1
            indx=unique(num_of_evt);
        
        
        
         
         % Getting the best result with the maximum difference between VR and CLVD 
         %indx=find(U(:,7)==max(U(:,7)));
         % STORED THE BEST RESULT IN THE FOLLOWING 2 VARIABLES
         Best_res_dat=[U(indx,:)];
         Best_res_txt=[UF(indx,:)];
         [rw col]=size(Best_res_txt);
         %% Reiterating for a refined grid result
         % Creating the parameters
         % Change year, month, day, hour, minute second and dep indices
      for rit=1:rw 
         
         
         s_time=[2019 08 21 00 00 00];
         e_time=[2019 08 21 23 00 00];
         year=str2num(Best_res_txt{rit,6});
         month=str2num(Best_res_txt{rit,7});
         start_day=str2num(Best_res_txt{rit,8});
         end_day=start_day;
         start_hour=str2num(Best_res_txt{rit,9});
         end_hour=start_hour+1;
         st_min=str2num(Best_res_txt{rit,10});
         st_sec=str2num(Best_res_txt{rit,11});
         
         g_space=0.1;
         gp=[Best_res_dat(rit,2) Best_res_dat(rit,1)];
         dep=str2double(extractBefore(Best_res_txt{rit,13},3));
         d_range=dep-6:2:dep+6;
          % Creating folder for storing paramer files
        par_folNam=strcat(num2str(year),num2str(month),num2str(start_day),'_',num2str(start_hour),'_',num2str(end_hour));
%         comEval(strcat('mkdir Param_AD/',par_folNam))
        comEval(strcat("cd ",parent_Dir,'Param_AD/',par_folNam));
         
        %% Create The parameter file for running moment tensor
         fid=fopen('grid_inv_ah.prm','w');
         fprintf(fid,'LON %3.1f,%3.1f\n',gp(2)-0.2,gp(2)+0.2);
         fprintf(fid,'LAT %3.1f,%3.1f\n',gp(1)-0.2,gp(1)+0.2);
         fprintf(fid,'DDEG %1.1f \n',g_space);
         fprintf(fid,'DTIME 1 \n');
         fprintf(fid,'MAXTIME 3400 \n');
         fprintf(fid,'DEPTH %2i,%2i,%2i,%2i,%2i,%2i,%2i \n',d_range.');
         fprintf(fid,'BTIME 94 \n');
         fprintf(fid,'TWIND 90 \n');
         fprintf(fid,'GFPATH /rhome/kchau012/bigdata/Taiwan_New/GF_Taiwan_3/ \n');
         fclose(fid);
         outdir_ref=eval('pwd');
         eval(strcat('cd ',parent_Dir));
         %% RUNNING the CMT code for the best Result
         addpath(genpath('/rhome/kchau012/bigdata/Cholame/home/'));
         pdir = strcat(parent_Dir,'MTI/'); % where the codes reside
         prmfile = strcat(parent_Dir,'Param_AD/',par_folNam,'/grid_inv_ah.prm');
        
         %prmfile = '/rhome/kchau012/bigdata/Data_Ridgecrest/CMT_Ridgecrest/grid_inv_ah.prm'; % parameter file
         comb=[Best_res_txt(rit,3:5)];Comb_Stns=3;
         for ikll=start_day:end_day

                    try
                    fntn = '7D';
                    d_pwd = parent_Dir;
                    s_hour = [year month ikll start_hour];
                    e_hour = [year month ikll end_hour];
                    outdir = strcat(parent_Dir,'Output/'); % outputs of MTI
                    % raw data from IRIS ORIGINAL
                    datae =strcat(parent_Dir,'OData/');
                    % Cleaned up data
                    %datac = '/rhome/kchau012/bigdata/Data_Ridgecrest/CMT_Ridgecrest/Clean_Data/';
                    cdfn=strcat(num2str(year),num2str(month),num2str(start_day),num2str(start_hour));
                    CLEAN_dir=strcat(parent_Dir,'Clean_Data/',cdfn,'/');
                    comEval(strcat('mkdir'," ",CLEAN_dir));
                    datac = CLEAN_dir;CLEAN_dir='';
                    
                    nhour = round((datenum([e_hour 0 0]) - datenum([s_hour 0 0]))*24); % numbers of hours
                    if exist(datac, 'dir') ~= 7
                        eval(['mkdir ' datac])
                    end


                    for ihr = 1: nhour

                        thedtn = datenum([s_hour 0 0]) + ((ihr-1)/24);
                        thedtv = datevec(thedtn);
                        thedtstr1 = datestr(thedtn, 'yyyy-mm-dd-HH');
                        thedtstr2 = datestr(thedtn, 'yy-mmmm');
                        str_sep1 = textscan(thedtstr1, '%s %s %s %s', 'delimiter', '-');
                        str_sep2 = textscan(thedtstr2, '%s %s', 'delimiter', '-');
                        datadh = [datae str_sep2{1,2}{1} str_sep2{1,1}{1} '/' str_sep1{1,1}{1} str_sep1{1,2}{1} str_sep1{1,3}{1} '/' str_sep1{1,4}{1} '/'];
                        outdirh = [outdir str_sep2{1,2}{1} str_sep2{1,1}{1} '/' str_sep1{1,1}{1} str_sep1{1,2}{1} str_sep1{1,3}{1} '/' str_sep1{1,4}{1}];
                        
                        datakk=datadh;
                        ppk1=[parent_Dir,'Data/' str_sep2{1,2}{1} str_sep2{1,1}{1} '/' str_sep1{1,1}{1} str_sep1{1,2}{1} str_sep1{1,3}{1} '/' str_sep1{1,4}{1} '/'];
%                         if ~exist(dfold, 'ppk1')
%                             % Folder does not exist so create it.
%                             mkdir(ppk1);
%                         end
                        eval(['mkdir ' ppk1]);
                        pth=fopen('pathway','w');
                        eval(['!rm ' ppk1 '*.SAC']);
                        cbf='';
                        for sacll=1:Comb_Stns

%                             p=(extractBetween(comb{sacll},1,4));
%                             p=p{:};
                            p=comb{sacll};
                            if sacll==1
                                fprintf(pth,'cp %s*%s*.SAC %s\n',datadh,p,ppk1);
                                cbf=strcat(cbf,p);
                            else
                                fprintf(pth,'cp %s*%s*.SAC %s\n',datadh,p,ppk1);
                                cbf=strcat(cbf,'_',p);
                            end
                            
                        end
                        fprintf(pth,'cp -r %szp %s',datadh,ppk1);
                        fclose(pth);
                        eval('!sh pathway');
                        datadh=ppk1;
                        % make output directory
                        eval(['mkdir ' outdirh]);
                        % Get the data
                        % remove all sac and zp files
                        eval(['!rm -r ' datac '*']);
                        % copy the files for the directory
                        copy_data(datadh, datac, '-v');
                        % Common beginnings of the filenames
                        filehd = sprintf('%s.%03i.%s.00.0000.%s.', str_sep1{1,1}{1}, dyofyr(thedtv(1:3)), str_sep1{1,4}{1}, fntn);
                        % filehd='2010.046.22.00.0000.TW.';
                        % Make saclist
                       eval(strcat("cd ",datac));
                        eval (['!ls ' filehd '*.SAC > sac.list']);
%                         for sacll=1:3
% 
%                             p=(extractBetween(comb{sacll},1,4));
%                             p=p{:};
%                             if sacll==1
%                                 eval (['!ls *' p '*.SAC > sac.list'])
%                             else
%                                 eval (['!ls *' p '*.SAC >> sac.list'])
%                             end
%                         end
                        % Go to the output directory from where MTI code will be run and output will be saved
                        eval(['cd ' outdirh])
                        eval(['!rm ./*' ])
                        eval(['!cp ' prmfile ' .'])
                        % Make station-channel list
                        eval(['!' pdir 'perl/make_cmt_list_ah.pl ' datac 'sac.list > cmt_stat.list'])   
                        % Remove instrument response and filter
                        eval(['!' pdir 'perl/bat_sac_deconv_ah.pl ' filehd ' ./cmt_stat.list ' datac])  
                        % Make station list with coordinates
                        eval(['!cp ' d_pwd '/make_sta_list.m .'])
                        make_sta_list (datac, './station.list')
                        % check data
                        eval(['cd ' d_pwd])
                        % check_data (datac, filehd) %runs check_data.m
                        % Remake saclist
                        eval (['cd ' datac])
                        eval (['!mv ./sac.list ./old_sac.list '])
                        eval (['!ls ' filehd '*.SAC > sac.list'])
                        % Remake station-channel list
                        eval(['cd ' outdirh])
                        eval(['!mv ./cmt_stat.list ./old_cmt_stat.list'])
                        eval(['!' pdir 'perl/make_cmt_list_ah.pl ' datac 'sac.list > cmt_stat.list'])
                        % Remake station list with coordinates
                        eval(['!mv ./station.list ./old_station.list'])
                        make_sta_list (datac, './station.list')
                        delete './make_sta_list.m'
                        % Run moment tensor inversion code
                        eval(['!' pdir 'perl/exe_grid_tdmrf_ah_forML3.pl ' filehd ' ./grid_inv_ah.prm ' str_sep1{1,1}{1} ' ' str_sep1{1,2}{1} ' '  str_sep1{1,3}{1} ' ' str_sep1{1,4}{1} ' 00 ' datac])
                        % Get the source parameters corresponding to the highest VR
                        eval(['!sort -k 11,11n grid_tdmrf_inv.out | tail -n 1 > event_hypoinfo.list'])
                        % Use GMT to plot results
                        eval(['!' pdir 'perl/prep_gmt_draw_ah_forML3.pl ' filehd ' ' datac])
                        eval(['!ps2raster -A -Tf plot_01.ps'])
                        % Copy stuff
                        eval(['!mv ' datac 'sac.list .']);
                        fold_name=strcat('Best_result_',num2str(rit)); 
                        eval(['!mkdir ' fold_name]);
                        eval(['!rm grid_tdmrf_inv.out']);
                        eval(['!cp * ./' fold_name]);
                        eval(['!rm *']);
                        %clear thedtn thedtv datadh datadh thedtstr2 thedtstr1 str_sep1 str_sep2 datadh outdirh filehd
                        %eval(['cd ' d_pwd])
                        eval(['cd ',fold_name]);
                        eval(strcat("!cp ",parent_Dir,'single_result_3stns.sh ./'));
                        eval(strcat("!cp ",parent_Dir,'fetch_result_3stns.sh ./'));
                        eval(strcat("!cp ",parent_Dir,'lldistkm.m ./'));
                        eval(['!sh fetch_result_3stns.sh']);
                        sR_load=load('Result.txt');
                        dd_evI_evFinal=lldistkm(sR_load(7:8),Best_res_dat(rit,1:2));
                        if dd_evI_evFinal <= 50
                            eval(['!sh single_result_3stns.sh'])
                        end
                        eval(['cd ../']);
                        
%                       eval(['cd /bigdata/aghoshlab/kchau012/Cascadia_VlFE/AUTO']);                 
                      end 
%                     catch
%                     end
%          end
%          clear all;

%% Match_Filtering the event to check to see if its REPEATING
% clear all
% close all

%addpath(genpath('/rhome/kchau012/bigdata/Cholame/home'))
if MF == 1
eval(strcat('!cp ',parent_Dir,'findCC.m ./'));
% evnt_dir='/bigdata/aghoshlab/kchau012/Cascadia_VlFE/AUTO/';

% Reading and cutting data 20s before the event starts to 200 secs from
% (event-20)
    datadir=datadh;
%   datadir='/bigdata/aghoshlab/kchau012/Data_Taiwan/BATS_network/Candidate2/';
    st_time = [year month start_day start_hour st_min st_sec-20]';
    durt=200; %in secs
    fnames = dir([datadir '*BH*.SAC']);
%     if length(fnames) > 12
%         fnames=fnames(4:length(fnames));
%     end
    
    for indd = 1: length(fnames)
    datak(indd) = coralReadSAC([datadir fnames(indd).name]);
    end
    optcut.cutType = 'absTime';
    optcut.absStartTime = st_time;
    optcut.absEndTime = st_time+[0 0 0 0 0 200]';
    optres.sintr_target = 0.1;
    [datak, ierr, optres] = coralResample(datak, optres);
    datak = coralFilter(datak, [0.02 0.05], 'bandpass');
    datar=datak;
    datak = coralCut(datak, optcut);
%     coralPlot(datak);

% Matching and finding indices
filenam=strcat('Date_repeats_',num2str(year),Best_res_txt{rit,7},Best_res_txt{rit,8},'_',Best_res_txt{rit,9},Best_res_txt{rit,10},Best_res_txt{rit,11},'.txt');
fo=fopen(filenam,'w');
dir_name=dir([strcat(parent_Dir,'/Day_Data') '/2011*']);
for out_loop=1:length(dir_name)
    try
    if out_loop ~= -1 
%     dir_name.name(out_loop)
    datadir=strcat(dir_name(out_loop).folder,'/',dir_name(out_loop).name,'/');
    %datadir='/bigdata/aghoshlab/kchau012/Taiwan_New/Jan_Mar/2010_Filtered_0.02_0.05/2010/20100414/';
    fnames = dir([datadir '*BH*.SAC']);
%     if length(fnames) > 12
%         fnames=fnames(4:length(fnames));
%     end
%     for indd = 1: length(fnames)
%         datag(indd) = coralReadSAC([datadir fnames(indd).name]);
%     end

    c=1;
    for i=1:3:length(datak)
        p=sprintf('*%s*.SAC',datak(i).staCode);
        fnames = dir([datadir p]);
        for indd = 1: length(fnames)
            datag(c) = coralReadSAC([datadir fnames(indd).name]);c=c+1;
        end
    
    end
    if length(datak)==length(datag)
    optres.sintr_target = 0.1;
    [datag, ierr, optres] = coralResample(datag, optres);
     cv=1;
     sm=zeros(length(datak),866400);
    for i =1:length(datak)
        r=findCC(datag(i).data,datak(i).data);
        sm(cv,1:length(r))=r';
        cv=cv+1;
    end
    
% if length(datak)==length(datag)
        SM=sm(:,length(datak(1).data):end-length(datak(1).data)+1);
        RM=rms(SM);
        i=1;o=1;
        fn=strcat('R_MF_',num2str(year),Best_res_txt{rw,7},Best_res_txt{rw,8},'_',Best_res_txt{rit,9},Best_res_txt{rit,10},Best_res_txt{rit,11});
        if ~exist(fn, 'dir')
                % Folder does not exist so create it.
                eval(['!mkdir ' fn]);%mkdir(fn);
        end
        %eval(['!mkdir ' fn]); 
        filename=strcat('./',fn,'/',dir_name(out_loop).name,'.txt');
        fid=fopen(filename,'w');
        ra=find(RM(:)>0.55);
        for r=1:length(ra)
           ra(r,2)=RM(ra(r,1));
        end

        Y=diff(ra(:,1));
        id=find(Y(:)>1000);
        si=1;
        if isempty(id) && isempty(ra) ~= 1
            pki=find(ra(:,2)==max(ra(:,2)));
            fprintf(fid,'%5.1f\n',ra(pki,1));
            fprintf(fo,'%s 1\n',dir_name(out_loop).name);
        else
            for i=1:length(id)
                if i < length(id)
                    ch=ra(si:id(i),:);
                    ind=find(ch(:,2)== max(ch(:,2)));
                    fprintf(fid,'%5.1f\n',ch(ind,1));
                    si=id(i)+1;
                elseif i == length(id)
                    ed=length(ra);
                    ch=ra(si:ed,:);
                    ind=find(ra(si:ed,2)== max(ra(si:ed,2)));
                    fprintf(fid,'%5.1f\n',ch(ind,1));
                end
            end
            fclose(fid);

            fprintf(fo,'%s %d\n',dir_name(out_loop).name,length(id));
        end   
end
clear ra RM SM
    end
    catch
    end
    clear datag
end
end
%% 
eval(['!cp ' filenam ' ' fn]);
% fcose(fo);
toc  
         
                     
                    catch
                    end
            end        
      end   

%% Creating space by removing unused data
          if ~isfile('Final_result.txt')
            comEval('!rm -r GP* ');
            fid=fopen('No_Result','w');
            fprintf(fid,'\nNo good results from this hour\n\n');
            fclose(fid);
          end
     elseif exist('num_of_evt','var') == 0 || isempty(num_of_evt)
         % Creating space by removing unused data
         comEval('!rm -r GP_*');
         fid=fopen('No_Result','w');
         fprintf(fid,'\nNo good results from this hour\n\n');
         fclose(fid);

     end
        else
            % Creating space by removing unused data
             comEval('!rm -r GP_*');
             fid=fopen('No_Result','w');
             fprintf(fid,'\nNo good results from this hour\n\n');
             fclose(fid);
             fclose(fidi);
            
            
        end
        
catch
end
end

