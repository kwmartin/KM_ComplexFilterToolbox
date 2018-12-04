X0=X2o;
rmvlOrdr = [3, 2, 1, -1, -1];
rmvlTypes = [7, 7, 7, 3, 4];
% X0=X2o;
% rmvlOrdr = [-1, 1, 2, 3, 0];
% rmvlTypes = [4, 7, 7, 7, 2];
zpk(X0)
[lddr, fail] = doRmvls(rmvlTypes, rmvlOrdr, X0, wps, ni)
dispLddr(lddr)
