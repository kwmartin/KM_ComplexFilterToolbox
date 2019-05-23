function test(sys)

npts = 10;
lim = 1e-2/2;
f = -lim:lim/npts:lim;
s = 2*pi*f;
freqRspns(sys, s);
