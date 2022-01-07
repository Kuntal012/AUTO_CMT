function [] = check_data (datac, filehd)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check filtered data, if any seismograms show anomalously high amplitude, 
% this code remove it from the directory where data are stored, and read 
% in for inversion
%
% INPUT:
% datac = directory where data are filtered and read in from
% filehd = first few characters of data filenames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


chans = {'E', 'N', 'Z'}; % channels
cf_fac = 3; % factors used to discard 'bad' seismograms



for ich = 1: length(chans)

    allns = dir([datac filehd '*BH' chans{ich} '*SAC_deconv']);
    nmpl = cell(length(allns),1);
    for ind = 1: length(allns)

        tmpd = coralReadSAC([datac allns(ind).name]);

        nmpl{ind} = tmpd.staCode;
        rdata(ind) = tmpd;
        clear tmpd
        
    end
        
    alld = zeros(rdata(2).recNumData, ind);
    for ind1 = 1: length(rdata)

        alld(:,ind1) = rdata(ind1).data;
         
    end

    % checking data
agv_alld = nanmean(abs(alld));
    

   med_alld = median(abs(alld));
%here you can do med_alld or avg_alld    
    igoodd = (agv_alld < (cf_fac*(median(agv_alld))));
    
    idel = (igoodd == 0);
    ndel = sum(idel);
    if ndel > 0.5
        dstn = nmpl(idel);
        for istd = 1: ndel
            fprintf('Delecting data %s%s',filehd,dstn{istd});
            eval(['!rm ' datac filehd dstn{istd} '..*SAC'])
            eval(['!rm ' datac filehd dstn{istd} '..*SAC_deconv'])
    
       end
    end

    clear allns nmpl rdata alld agv_alld med_alld igoodd idel ndel dstn ind ind1 istd
    
end
