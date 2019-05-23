% 8 movable poles, 1 pole at infinity, 0 fixed poles,
% wp = 0.025 to 0.075, 0.05dB elliptic passband
% 100 Monte-Carlo runs; takes a bit of time to run and plot
% lower stop-band loss is around 101dB

w_shift = 0.0j;
p = [-0.35 -0.25 -0.1 -0.08 0.08 0.1 0.25 0.35]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -0.025; % lower passband edge
wp(2) = 0.025; % upper passband edge
ws = [-0.49 -0.035 0.035 0.49];
as = [70 50 50 70];
Ap = 0.05; % the passband ripple in dB
px = [];
ONE_STP = 0;
[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.05);

tic
% A positive-pass continuous-time filter with a elliptic pass-band
cscdFltr1 = dsgnCascadeFltr(p_,px_,ni,wp_,ws_,as,Ap,'elliptic');
H = cscdFltr1.getSystem();
% if internal object update not needed just use H = cscdFltr1.sys
toc
cscdFltr1.plotGn(wp_, ws_, -160, 2);
tic
runMcCscd(cscdFltr1, wp_, 2e-5, 0, 100, [-160, 2]);
toc
drawnow;
cscdHndl = gcf;
% print('../examples/Figures/csc_fltr_1_8_0','-dpdf');
print('../examples/Figures/csc_fltr_1_8_0','-dpng');

a=1; % can place a breakpoint here to inspect objects