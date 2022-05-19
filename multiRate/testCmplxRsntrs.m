simCase = 1;

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
    zin = exp(1j*t(:)*win);
elseif simCase == 1
    % npts = 16384;
    npts = 2048;
    t = (0:(npts-1))';
    zin = zeros(npts, 1);
    % zin(1:64:16384) = 1.0;
    zin(1) = 1;
end

Gis = [-0.23514695, 0.70710681, -0.97195983, 1.0, ...
    -0.97195983, 0.70710681, -0.23514695];


Nr = length(fp);
x0 = ones(1,Nr);
for j = 1:Nr
    % rsntrs(j) = cmplxRsntrClass(wp(j), x0(j));
    rsntrs(j) = cmplxRsntrClass(wp(j), x0(j), N);
    % rsntrs(j) = cmplxRsntrClass();
end
xerr = 0.0;
xi = 0.0;
Xe = [];
G = 1/N;
Xo2 = [];

[Xe, Xo2] = simCmplxRsntrs1(zin, rsntrs, G, Gis);
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
