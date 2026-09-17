% testCmplxRsntrs.m
simCase = 1;
pr = @(x) plot(real(x))
pq = @(x) plot(imag(x))

N = 256;
fp = 5/N : 1/N: 11/N;
wp = 2*pi*fp;
if simCase == 0
    fin = fp(4);
    k = 2*sin(wp/2);
    win = 2*pi*fin;
    N = length(wp);
    npts = 2^14;
    t = (0:(npts-1))';
    zin = exp(j*t(:)*win);
elseif simCase == 1
    % npts = 16384;
    npts = 2048;
    t = (0:(npts-1))';
    zin = zeros(npts, 1);
    % zin(1:64:16384) = 1.0;
    zin(1) = 1;
end

npts = 32768;
t = (0:(npts-1))';
Resons = [];
wp = 2*pi*[1/24, 1.5/24];
xin = exp(j*t(:)*wp(1)*1.12) + 0.4*exp(j*t(:)*wp(2)*0.9);
Nr = length(wp);
x0 = ones(1,Nr);
for k = 1:Nr
    rsntrs(k) = cmplxRsntrClass(wp(k), x0(k));
end
Gfb = 0.125;
[Xout, Xerr, Xsen, deltw, w] = simCmplxResons(xin, rsntrs, Gfb);
figure
pr(Xout(:,2))
hold
pq(Xout(:,2))
pr(Xout(:,1))
pq(Xout(:,1))
figure
plot(imag(deltw(:,1)))
hold
plot(imag(deltw(:,2)))
figure
pr(Xerr)
figure
plot(w(:, 1))
hold
plot(w(:, 2))
aa=0;

Res = cmplxRsntrClass(2*pi/16, 1.0);
win = 1.1*2*pi/16;
xin = 0.25*sum(exp(j*t(:)*win),2);
Gfb = 0.25;
[Xout, Xerr, Xsen, deltw, w] = simCmplxRes(xin, Res, Gfb);
figure;
plot(t, [real(Xerr(:)), imag(Xerr(:))]);
figure;
plot(t, [real(Xout(:)), imag(Xout(:))]);
figure;
plot(t, [real(deltw(:)), imag(deltw(:))]);
figure;
plot(t, w);

Gis = [-0.23514695, 0.70710681, -0.97195983, 1.0, ...
    -0.97195983, 0.70710681, -0.23514695];

Nr = length(fp);
x0 = zeros(1,Nr);
fp = 5/N : 1/N: 11/N;
wp = 2*pi*fp;
npts = 2048;
t = (0:(npts-1))';
zin = zeros(npts, 1);
% zin(1:64:16384) = 1.0;
zin(1) = 1;

for k = 1:Nr
    % rsntrs(k) = cmplxRsntrClass(wp(k), x0(k));
    rsntrs(k) = cmplxRsntrClass(wp(k), x0(k));
    % rsntrs(j) = cmplxRsntrClass();
end
xerr = 0.0;
xi = 0.0;
Xe = [];
G = 1/N;
Xo2 = [];

%[Xe, Xo2] = simCmplxRsntrs1(zin, rsntrs, G, Gis);
[Xe, Xo2] = simCmplxRsntr0(zin, rsntrs, Gis, G);
figure;
plot(t, [real(Xe(:)), imag(Xe(:))]);
figure;
plot(t, [real(Xo2(:)), imag(Xo2(:))]);
dB = plotRspnsd(Xo2, [-120, 2]);

Xs = zeros(1,N);
Xs(5:11) = 1;
Xos = zeros(1, N/4);
Xos(2) = 8;
[Xe3, Xo3] = simCmplxRsntrs2(zin, Xs, Xos, G, Gis);
figure;
plot(t, [real(Xo3(:,2)), imag(Xo3(:,2))]);
dB = plotRspnsd(Xo3(:,2), [-130, 2], true);
print('Freq_Rspns_64Chln','-dpng');
figure
plot(t, real(Xe3(:,1)));
Xe3(1)=0;
Xe3(65) = 0;
figure
plot(t,[real(Xe3), imag(Xe3)]);
a = 1;
