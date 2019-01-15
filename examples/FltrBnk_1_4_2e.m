% a 64 channel filter-bank simulation based on monotonic filters having 4
% movable loss-poles

N = 64;
delta_f = 1/N;
%w_shift = pi*j;
w_shift = 0.0j;
% initial guess at finite loss poles
p = [-delta_f*2.5 -delta_f*1.5 delta_f*1.5 delta_f*2.5];
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -delta_f/2; % lower passband edge
wp(2) = delta_f/2; % upper passband edge
ws = [-0.49 -delta_f*0.75 delta_f*0.75 0.49];
as = [50 50 50 50];
Ap = 0.51; % the passband ripple in dB
px = [-delta_f*1.0 delta_f*1.0];
ONE_STP = 0;

H1 = dsgnDigitalFltr(p, px, ni, wp, ws, as, Ap, 'elliptic');
plot_drsps(H1, wp, ws, 'b', [-0.5 0.5 -120 1]);
cscdFltr1 = mkCscdFltrD(H1, wp);
%cscdFltr1.plotGn(wp, ws, -100, 2);
xin = zeros(8192,1);
xin(1) = 1;
ylim = [-120 2];

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
    if (i~= 40)
        sum = sum + Out(:,i);
    end
end
plotRspns(sum, [-0.5 0.5], 'r', ylim);
toc

a=1;