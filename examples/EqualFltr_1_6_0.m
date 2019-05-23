% a filter-bank simulation based on monotonic filters having 4
% movable loss-poles

fltrNm = 'EqualFltr_1_6_0';
N = 8;
delta_f = 1/N;
%w_shift = pi*j;
w_shift = 0.0j;
p = [-0.4 -0.3 -0.2 0.2 0.3 0.4]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -delta_f/2; % lower passband edge
wp(2) = delta_f/2; % upper passband edge
ws = [-0.49 -delta_f delta_f 0.49];
as = [50 50 50 50];
%Ap = 1.19; % the passband ripple in dB
Ap = 0.001; % the passband ripple in dB
px = [];
ONE_STP = 0;

% Hbssl = bessel_filt(11, [-1 1], -6.0206);
% plot_crsps(Hbssl, [-1 1], [-10 10], 'b',[-20 20 -180 2]);
% [lgH, phH, gdH, dLdW, dTdW] = plot_am_ph_gd(Hbssl, [-1 1], [-10 10], 'b');

Ap = 1.702;
cscdFltr1 = dsgnCascadeFltr(p,px,ni,wp,ws,as,Ap,'equiGD');
H1 = cscdFltr1.getSystem();
plot_dam_ph_gd(H1, wp, ws, 'b');

%cscdFltr1.plotGn(wp, ws, -80, 2);

cscd2Yml(cscdFltr1, strcat(fltrNm, '.yml'));

xin = zeros(8192,1);
xin(1) = 1;
%xin(1:64:8192) = 1;
ylim = [-200 2];

Out1 = cscdFltr1.sim(xin, 0);
h0 = figure('Position',[800 100 600 600]);
plot(real(Out1));
hold('on');
plot(imag(Out1), 'r');

h1 = figure('Position',[800 100 600 600]);
[ax0 ax0, f, ymRef] = plotRspns(Out1, [-0.1 0.1], 'b', ylim);

Xin = zeros(256,N);
Xin(1,4) = 1;
tic
Out1 = simCscdFltrBnk3(cscdFltr1, Xin, delta_f);
In2 = sum(Out1,2);
%In2 = Out1;
Out = simCscdFltrBnk(cscdFltr1, In2, delta_f);
toc
figure;
plot(real(Out(:,4)), 'b');
hold on;
plot(imag(Out(:,4)), 'r');
plot(real(Out(:,3)), 'c');
plot(imag(Out(:,3)), 'g');
plot(real(Out(:,5)), 'm');
plot(imag(Out(:,5)), 'y');


tic
hndl = figure('Position',[800 100 600 600]);
[ax1 ax2, f, ymRef] = plotRspns(Out(:,1), [-0.05 0.1], 'b', ylim);
hold(ax1, 'on');
hold(ax2, 'on');
Sum = Out(:,1);
for i = 2:N
    plotRspns(Out(:,i), [-0.5 0.5], 'b', ylim);
    Sum = Sum + Out(:,i);
end
plotRspns(Sum, [-0.5 0.5], 'r', ylim);
toc

drawnow;
cscdHndl = gcf;
print(strcat('Figures/', fltrNm), '-dpng');

a=1;