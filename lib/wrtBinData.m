function wrtBinData(db, outDir, rcrdNmb, flLst)
% reads wfdb data files with names flLst[i].dat residing in db
% and writes them out into binary files flLst[i].bin. First the number of
% samples is written at int64, and then the samples are written as doubles.

for i = 1:length(flLst)
    inRcrd = strcat(db, flLst{i});
    dt = getData(inRcrd, rcrdNmb, 250);
    outFl = strcat(outDir, flLst{i}, '.bin');
    fd = fopen(outFl, 'w');
    fwrite(fd,length(dt),'int64');
    fwrite(fd,dt,'double');
    fclose(fd);
end