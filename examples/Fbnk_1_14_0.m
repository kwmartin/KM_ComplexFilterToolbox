% a filter-bank simulation based on monotonic filters having 4
% movable loss-poles

fltrNm = 'Fbnk_1_8_0';
N = 64;
delta_f = 1/N;
%w_shift = pi*j;
w_shift = 0.0j;
p = [-0.3 -0.25 -0.2 -0.15 -0.12 -0.1 -0.08 0.08 0.1 0.12 0.15 0.2 0.25 0.3]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -delta_f/2; % lower passband edge
wp(2) = delta_f/2; % upper passband edge
% ws = [-0.499 2.0*wp 0.499];
ws = [-0.499 -0.032 0.032 0.499];
as = [50 50 50 50];
%Ap = 1.21; % the passband ripple in dB
Ap = 1.2; % the passband ripple in dB
px = [];
ONE_STP = 0;

% Hbssl = bessel_filt(11, [-1 1], -6.0206);
% plot_crsps(Hbssl, [-1 1], [-10 10], 'b',[-20 20 -180 2]);
% [lgH, phH, gdH, dLdW, dTdW] = plot_am_ph_gd(Hbssl, [-1 1], [-10 10], 'b');

%Ap = 3.0103;
% Ap = 2.09;
Ap = 1.06;
deltGD = 0.05;
useWs = 1;
H = equiGdDigital(p,px,ni,wp,ws,as,Ap,deltGD,useWs);
cscdFltr1 = mkCscdFltrD2(H, wp);
H1 = cscdFltr1.getSystem();
plot_dam_ph_gd(H1, [-0.5 0.5], -100, 'b');

%cscdFltr1.plotGn(wp, ws, -80, 2);

cscd2Yml(cscdFltr1, strcat(fltrNm, '.yml'));

xin = ones(8192,1);
xin(1) = 1;
%xin(1:64:8192) = 1;
ylim = [-120 2];

Out1 = cscdFltr1.sim(xin, 0);
h0 = figure('Position',[800 100 600 600]);
plot(real(Out1));
hold('on');
plot(imag(Out1), 'r');

h1 = figure('Position',[800 100 600 600]);
[ax0 ax0, f, ymRef] = plotRspns(Out1, [-0.1 0.1], 'b', ylim);

Xin = zeros(256,N);
Xin(1,:) = 1;
tic
Out1 = simCscdFltrBnk3(cscdFltr1, Xin, delta_f);
clear sum; % one of the routines has been over-loading "sum"; be warned we'll find you
In2 = sum(Out1,2);
%In2 = Out1;
Out = simCscdFltrBnk(cscdFltr1, Xin, delta_f);
%Out = simCscdFltrBnk(cscdFltr1, In2, delta_f);
toc
figure;
plot(real(Out(:,4)), 'b');
hold on;
plot(imag(Out(:,4)), 'r');
plot(real(Out(:,3)), 'c');
plot(imag(Out(:,3)), 'g');
plot(real(Out(:,5)), 'm');
plot(imag(Out(:,5)), 'y');

%Out2 = zeros(8192, N);
GainVct = ones(N,1);
GainVct(20:23) = 1;
GainVct(28:29)=1;
GainVct(39:43) = 1;
GainVct(51:53) = 1;
GainMtrx = diag(GainVct);
Out2 = Out*GainMtrx;

tic
hndl = figure('Position',[800 100 600 600]);
[ax1 ax2, f, ymRef] = plotRspns(Out2(:,1), [-0.05 0.1], 'b', ylim);
Sum = Out2(:,1);
hold(ax1, 'on');
hold(ax2, 'on');
for i = 2:N
    % if (i == 40) | (i == 41) | (i == 42) | (i == 43) | (i == 44)
    % if (i > 34) & (i < 63)
    if 1
        plotRspns(Out2(:,i), [-0.5 0.5], 'b', ylim);
        Sum = Sum + Out2(:,i);
    end
end
plotRspns(Sum, [-0.5 0.5], 'r', ylim);
toc

drawnow;
cscdHndl = gcf;
ExmplDir = '/home/martin/Dropbox/Matlab/Complex/KM_ComplexFilterToolbox/examples/';
FigDir = strcat(ExmplDir, 'Figures/');
print(strcat(FigDir, fltrNm), '-dpng');

a=1;