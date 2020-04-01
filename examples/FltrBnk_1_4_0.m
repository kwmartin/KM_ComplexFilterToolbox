% a 1024 channel filter-bank simulation based on monotonic filters having 4
% movable loss-poles
fltrNm = 'FltrBnk_1_4_0';
RootDir = getenv('CMPLXROOT');
if isempty(RootDir)
    setenv('CMPLXROOT', '/home/martin/Dropbox/Matlab/Complex/KM_ComplexFilterToolbox');
end

N = 256;
delta_f = 1/N;
%w_shift = pi*j;
w_shift = 0.0j;
p = [-0.2 -0.1 0.1 0.2]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
fp = []; ws = [];
fp(1) = -delta_f/2; % lower passband edge
fp(2) = delta_f/2; % upper passband edge
ws = 2*pi*[-0.49 -1.0*delta_f 1.0*delta_f 0.49];
as = [50 50 50 50];
% Ap = 4.0; % the passband ripple in dB
Ap = 1.6; % the passband ripple in dB
px = [];
ONE_STP = 0;
wp = 2*tan(pi*fp);

H = design_dig_filt(p,px,ni,wp,ws,as,Ap,'monotonic');
plot_drsps(H, fp, 'b', [-80 1]);
cscdFltr1 = mkCscdFltrD2(H, wp);

cscd2Yml(cscdFltr1, strcat(RootDir, '/examples/', fltrNm, '.yml'));

%cscdFltr1.plotGn(wp, ws, -100, 2);
xin = zeros(8192,1);
xin(1) = 1;
ylim = [-60 2];

tic
Out = simCscdFltrBnk(cscdFltr1, xin, delta_f);
toc

tic
hndl = figure('Position',[800 100 600 600]);
[ax1 ax2, f, ymRef] = plotRspns(Out(:,1), [-0.05 0.1], 'b', ylim);
hold(ax1, 'on');
hold(ax2, 'on');
sum_ = Out(:,1);
for i = 2:N
    plotRspns(Out(:,i), [-0.5 0.5], 'b', ylim);
    sum_ = sum_ + Out(:,i);
end
plotRspns(sum_, [-0.5 0.5], 'r', ylim);
toc

a=1;