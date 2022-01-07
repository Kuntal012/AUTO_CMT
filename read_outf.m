clear all
clc

rdir = '/home/ehuesca/VLF/results/';
%rdir = '/auto/proj/aghosh2/VLFE/output_tailnet/';
s_hour = [2012 9 11 00];
e_hour = [2012 9 12 00];

nhour = round((datenum([e_hour 0 0]) - datenum([s_hour 0 0]))*24); % numbers of hours

%load /auto/home/aghosh/Ito_codes/test_codes/wrapper/output_big/August10/20100806/00/grid_tdmrf_inv.out
for ihr = 1: nhour
    
    thedtn = datenum([s_hour 0 0]) + ((ihr-1)/24);
    thedtstr1 = datestr(thedtn, 'yyyy-mm-dd-HH');
    thedtstr2 = datestr(thedtn, 'yy-mmmm');
    str_sep1 = textscan(thedtstr1, '%s %s %s %s', 'delimiter', '-');
    str_sep2 = textscan(thedtstr2, '%s %s', 'delimiter', '-');
    
    disp(['Working on ' datestr(thedtn)])
    
    fdir = [rdir str_sep2{1,2}{1} str_sep2{1,1}{1} '/' str_sep1{1,1}{1} str_sep1{1,2}{1} str_sep1{1,3}{1} '/' str_sep1{1,4}{1} '/'];
    load([fdir 'grid_tdmrf_inv.out'])
    
    
    catall = grid_tdmrf_inv;
    clear grid_tdmrf_inv
    
    catsort = sortrows(catall,6);
    
    if ihr == 1
        nitr = find(catsort(:,6)==catsort(1,6), 1, 'last');
        nwin = size(catsort,1)/nitr;
        catbig = NaN*zeros(nwin*nhour, size(catsort,2));
        newcat = NaN*zeros(nwin, size(catsort,2));
        
    end
    
    % newcat = NaN*zeros(nwin, size(catsort,2));
    for ind = 1: nwin
        
        k1 = ((ind-1)*nitr)+1;
        k2 = ind*nitr;
        
        tmpcat = catsort(k1:k2,:);
        [vrm, vri] = max(tmpcat(:,11));
        newcat(ind,:) = tmpcat(vri,:);
        
        clear k1 k2 tmpcat vrm vri
        
    end
    
    k_1 = ((ihr-1)*nwin)+1;
    k_2 = ihr*nwin;
    catbig(k_1:k_2,:) = newcat;
    eval(['save ' fdir 'outperwin.mat newcat'])
    newcat = NaN*newcat;
    
    clear ind fdir thedtn thedtstr1 thedtstr2 str_sep1 str_sep2 k_1 k_2 catall catsort
    
end

 h=figure(1);
 set(h, 'position', [0 0 1500 1000]);
 clf
 
 plot(datenum(catbig(:,1:6)), catbig(:,11));
 datetick('x', 0)

 saveas(h,'20120910', 'png')