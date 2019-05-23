% 7 movable loss-poles, 1 loss pole at infinity, 0 fixed poles
% wp = 0.025 to 0.125, 0.05dB elliptic passband
% 100 Monte-Carlo runs; takes about a minute to run and plot
% lower stop-band loss is around 105dB

p = [-0.4 -0.25 -0.125 -0.1 -0.05 0.25 0.35]; % initial guess at movable loss poles
px = []; % fixed poles
ni=1; % number of loss poles at infinity
wp = [0.025 0.125];
ws = [0 0.2];
as = [20 20];
Ap = 0.025; % the passband ripple in dB

cscdFltr = dsgnCscdFltr(p,px,ni,wp,ws,as,Ap,'elliptic');
cscdFltr.plotGn(wp, ws, -160, 2);

freq_shtf = 0.0;
tic
runMcCscd(cscdFltr, wp, 5e-5, freq_shtf, 100, [-160, 2]);
toc

a=1;