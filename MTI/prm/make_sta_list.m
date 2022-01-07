function [] = make_sta_list (ddir, filename)

% ddir = '/auto/home/aghosh/Ito_codes/test_codes/Cascadia/seisg/data_obsv/';
% filename = 'station.list';
thestr = '*BHE*SAC';

allns = dir([ddir thestr]);
info = cell(length(allns),4);
for ind = 1: length(allns)
    
    tmpd = coralReadSAC([ddir allns(ind).name]);
    info(ind,:) = {tmpd.staCode tmpd.staLat tmpd.staLon tmpd.staElev/1000};
    clear tmpd
    
end
clear ind

[nrows, ncols] = size(info);
fid = fopen(filename, 'w');

for row=1:nrows
    fprintf(fid, '%s %d %d %d\n', info{row,:});
end

fclose(fid);