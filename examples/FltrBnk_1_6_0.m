% a 128 channel filter-bank simulation based on monotonic filters having 6
% movable loss-poles

N = 128;
delta_f = 1/N;
%w_shift = pi*j;
w_shift = 0.0j;
p = [-0.2 -0.15 -0.1 0.1 0.15 0.2]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -delta_f/2; % lower passband edge
wp(2) = delta_f/2; % upper passband edge
ws = [-0.49 -1.0*delta_f 1.0*delta_f 0.49];
as = [50 50 50 50];
Ap = 1.18; % the passband ripple in dB
px = [];
ONE_STP = 0;

H1 = dsgnDigitalFltr(p, px, ni, wp, ws, as, Ap, 'monotonic');
plot_drsps(H1, wp, ws, 'b', [-0.5 0.5 -80 1]);
cscdFltr1 = mkCscdFltrD(H1, wp);
%cscdFltr1.plotGn(wp, ws, -100, 2);
xin = zeros(8192,1);
xin(1) = 1;
ylim = [-80 2];

tic
Out = simCscdFltrBnk(cscdFltr1, xin, delta_f);
toc

tic
hndl = figure('Position',[800 100 600 600]);
[ax1 ax2, f, ymRef] = plotRspns(Out(:,1), [-0.05 0.1], 'b', ylim);
hold(ax1, 'on');
hold(ax2, 'on');
sum = Out(:,1);
for i = 2:N
    plotRspns(Out(:,i), [-0.5 0.5], 'b', ylim);
    sum = sum + Out(:,i);
end
plotRspns(sum, [-0.5 0.5], 'r', ylim);
toc

a=1;