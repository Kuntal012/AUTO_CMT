addpath(genpath('/rhome/kchau012/bigdata/Cholame/home/'));

clc
clear all
tst = clock;

pdir = '/rhome/kchau012/bigdata/Taiwan_New/MTI/'; % where the codes reside
prmfile = '/rhome/kchau012/bigdata/Taiwan_New/MTI/grid_inv_ah.prm'; % parameter file

%fntn = 'CS';
fntn = '7D';
d_pwd = pwd;

s_hour = [2010 2 24 1];
e_hour = [2010 2 24 2];

outdir = '/rhome/kchau012/bigdata/Taiwan_New/Res_Taiwan_20100224/'; % outputs of MTI

datae = '/rhome/kchau012/bigdata/Taiwan_New/0215_p1/'; % raw data from IRIS
datac = '/rhome/kchau012/bigdata/Taiwan_New/MTI_Taiwan_20100224/'; % cleaned up datA

nhour = round((datenum([e_hour 0 0]) - datenum([s_hour 0 0]))*24); % numbers of hours

% make directory for cleaned up data

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
    
    % make output directory
    eval(['mkdir ' outdirh])
    
    % Get the data
    % remove all sac and zp files
    eval(['!rm -r ' datac '*'])
    % copy the files for the directory
    copy_data(datadh, datac, '-v')
    
    
    % Common beginnings of the filenames
     filehd = sprintf('%s.%03i.%s.00.0000.%s.', str_sep1{1,1}{1}, dyofyr(thedtv(1:3)), str_sep1{1,4}{1}, fntn);
    % filehd='2010.046.22.00.0000.7D.';
    % Make saclist
    eval (['cd ' datac])
    eval (['!ls ' filehd '*.SAC > sac.list'])
    
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
 check_data (datac, filehd) %runs check_data.m

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
    eval(['!mv ' datac 'sac.list .'])
    %eval(['cd /rhome/kchau012/bigdata/Taiwan_New']);
    %clear thedtn thedtv datadh datadh thedtstr2 thedtstr1 str_sep1 str_sep2 datadh outdirh filehd
    eval(['cd ' d_pwd])
    
end

disp(['I took ' num2str(round((etime(clock, tst))/60)) ' minutes to finish this job'])




