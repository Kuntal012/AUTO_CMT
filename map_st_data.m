clear all

%% declare some variables

pdir = '/home/ahutchison/VLF/MTI/'; % where the codes reside
datadh = '~/VLF/datafetch/Data/';
datac = '/home/ahutchison/VLF/out_dir/';

thestr = '*BHZ*SAC';
thestr1 = '*BHZ*SAC_deconv';

load /proj/aghosh1/AofA_Kan/EQ/WAcoastline.dat

%% REMOVE INSTRUMENT RESPONSE
% Get the data
% remove all sac and zp files
eval(['!rm -r ' datac '*'])
% copy the files for the directory
copy_data(datadh, datac, '-v')

% get file-header
allns = dir([datac thestr]);
filehd = allns(1).name(1:23);
clear allns

% Make saclist
eval (['cd ' datac])
eval (['!ls ' filehd '*.SAC > sac.list'])

% Make station-channel list
eval(['!' pdir 'perl/make_cmt_list_ag.pl ' datac 'sac.list > cmt_stat.list'])

% Remove instrument response and filter
eval(['!' pdir 'perl/bat_sac_deconv_ag.pl ' filehd ' ./cmt_stat.list ' datac])

%% get the coordinates
% input arg: clean data directory, filehd

chans = {'E', 'N', 'Z'}; % channels
cf_fac = 3; % factors used to discard 'bad' seismograms

for ich = 1: 1%length(chans)
    
    allns = dir([datac filehd '*BH' chans{ich} '*SAC_deconv']);
    coord = NaN*zeros(length(allns),2);
    nmpl = cell(length(allns),1);
    for ind = 1: length(allns)
        
        tmpd = coralReadSAC([datac allns(ind).name]);
        coord(ind,:) = [tmpd.staLat tmpd.staLon];
        nmpl{ind} = tmpd.staCode;
        rdata(ind) = tmpd;
        clear tmpd
        
    end
    
    %%
    % Map/grid limit
    mlat = [min(coord(:,1))-0.2 max(coord(:,1))+0.2];
    mlon = [min(coord(:,2))-0.2 max(coord(:,2))+0.2];
    % Figuring out aspect ratio
    [xdis, xadis] = gcdist ([mean(mlat) mlon(1)], [mean(mlat) mlon(2)]);
    [ydis, yadis] = gcdist ([mlat(1) mean(mlon)], [mlat(2) mean(mlon)]);
    %%
    figure(1)
    clf
    
    subplot 121
    hold on
    plot (WAcoastline(:, 1), WAcoastline(:, 2), 'k', 'linewidth', 1)
    plot(coord(:,2), coord(:,1), 's', 'markeredgecolor', 'k', 'markerfacecolor', 'r', 'markersize', 8)
    text(coord(:,2)+0.02, coord(:,1),nmpl)
    xlim (mlon)
    ylim (mlat)
    set (gca,'FontSize',14, 'plotboxaspectratio', [1 (ydis/xdis) 1])
    title('All stations')
    
    %% Plotting all data
    data = rdata;
    
    alld = NaN*zeros(data(1).recNumData, ind);
    for ind1 = 1: length(data)
        
        alld(:,ind1) = data(ind1).data;
        
    end
    
    figure(2)
    clf
    coralPlot(rdata)
    
    figure(4)
    clf
    
    subplot 211
    hold on
    plot(alld)
    legend(nmpl)
    
    %% checking data
    agv_alld = mean(abs(alld));
    med_alld = median(abs(alld));
    
    igoodd = (agv_alld < (cf_fac*(median(agv_alld))));
    goodd = alld(:, igoodd);
    
    gdata = rdata(igoodd);
    
    figure(4)
    subplot 212
    hold on
    plot(goodd)
    %legend(nmpl)
    
    idel = (igoodd == 0);
    ndel = sum(idel);
    if ndel > 0.5
        dstn = nmpl(idel);
        for istd = 1: ndel
            eval(['!rm ' datac filehd dstn{istd} '..*SAC'])
            eval(['!rm ' datac filehd dstn{istd} '..*SAC_deconv'])
        end
    end
    
    clear allns coord nmpl rdata data alld agv_alld med_alld igoodd goodd gdata idel ndel dstn ind ind1 istd
    
end

% %% COPIED
%
%     % Get the data
%     % remove all sac and zp files
%     eval(['!rm -r ' datac '*'])
%     % copy the files for the directory
%     copy_data(datadh, datac, '-v')
%
%
%     % Common beginnings of the filenames
%     filehd = sprintf('%s.%03i.%s.00.0000.%s.', str_sep1{1,1}{1}, dyofyr(thedtv(1:3)), str_sep1{1,4}{1}, fntn);
%
%     % Make saclist
%     eval (['cd ' datac])
%     eval (['!ls ' filehd '*.SAC > sac.list'])
%
%     % Go to the output directory from where MTI code will be run and output will be saved
%     eval(['cd ' outdirh])
%     eval(['!rm ./*' ])
%     eval(['!cp ' prmfile ' .'])
%     % Make station-channel list
%     eval(['!' pdir 'perl/make_cmt_list_ag.pl ' datac 'sac.list > cmt_stat.list'])
%
%     % Remove instrument response and filter
%     eval(['!' pdir 'perl/bat_sac_deconv_ag.pl ' filehd ' ./cmt_stat.list ' datac])
%
%     % Make station list with coordinates
%     eval(['!cp ' d_pwd '/make_sta_list.m .'])
%     make_sta_list (datac, './station.list')
%     delete './make_sta_list.m'
