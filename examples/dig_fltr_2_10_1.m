% Top level for designing a 9'th order complex digital bandpass filter with 6
% movable poles, one fixed pole at dc, and 2 fixed poles at -1. The
% passband is at postive frequencies only between 0.05 and 0.1 Hz.

p = 2*pi*[-0.35 -0.3 -0.2 -0.15 -0.1 -0.05 0.16 0.18 0.25 0.35]; % initial guess at moveable finite loss poles
px = [0.0]; % fixed pole
ni=2; % number of loss poles at infinity
wpHz = [0.05 0.1];
wpRd = 2*pi*wpHz;
wp = 2*tan(wpRd./2.0); % predistort passband
ws = 2*pi*[-0.0 0.15]; % lower and upper stopband frequencies
ws = 2*pi*[-0.0 0.15]; % lower and upper stopband frequencies
as = [20 20];
Ap = 0.05; % the passband ripple in dB
type = 'elliptic'


H = design_dig_filt(p,px,ni,wp,ws,as,Ap,type);
cscdFltr = mkCscdFltrD(H, wp);
plotSimCscd(cscdFltr, wpHz, ws, -300, 0, 'b');
tic
drawnow;
cscdHndl = gcf;
% print('../examples/Figures/dig_fltr_2_8_1','-dpdf');
print('../examples/Figures/dig_fltr_2_10_1/dig_fltr_2_10_1_mcbq','-dpng');
hndl1 = figure('Position',[800 100 600 600]);
runMcCscd(cscdFltr, wpHz, 1e-5, 0, 100, [-300, 10], 'r');
cscdFltr2 = mkCscdFltrD2(H, wp);
plotSimCscd(cscdFltr2, wpHz, ws, -300, 0, 'b');
runMcCscd(cscdFltr2, wpHz, 1e-5, 0, 100, [-300, 10], 'b');
drawnow;
cscdHndl = gcf;
print('../examples/Figures/dig_fltr_2_10_1','-dpdf');
print('../examples/Figures/dig_fltr_2_10_1/dig_fltr_2_10_1_mc','-dpng');
toc

a=1;