% 8 movable poles, 1 pole at infinity, 1 fixed pole,
% wp = -0.025 to 0.075, 0.05dB elliptic passband
% 100 Monte-Carlo runs; takes a bit of time to run and plot
% lower stop-band loss is around 158dB
% This examples takes about 1.5 minutes to run (mostly for Monte-Carlo sims)
% This filter is about the limit of the toolboxes capabilities

%w_shift = pi*j;
w_shift = 0.0j;
p = [-0.35 -0.25 -0.1 -0.08 -0.06 0.08 0.25 0.35]; % initial guess at finite loss poles
px = [-0.05];
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -0.025; % lower passband edge
wp(2) = 0.025; % upper passband edge
ws = [-0.49 -0.049 0.049 0.49];
as = [70 50 50 70];
Ap = 0.05; % the passband ripple in dB
ONE_STP = 0;
% A positive-pass continuous-time filter with a elliptic pass-band

[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.05);
% The next few commented lines shows how to do design and return H
% H = dsgnDigitalFltr(p_, px_, ni, wp_, ws_, as, Ap, 'elliptic');
% [ax1, ax2] = plot_drsps(H, wp_, ws_, 'b', [-0.5 0.5 -200 1]);
% cscdFltr1 = mkCscdFltrD(H, wp_);
% This functionality has now been encapsulated in dsgnCascadeFltr()
tic
cscdFltr1 = dsgnCscdFltr(p_,px_,ni,wp_,ws_,as,Ap,'elliptic');
H = cscdFltr1.getSystem();
% if internal object update not needed just use H = cscdFltr1.sys
toc
cscdFltr1.plotGn(wp_, ws_, -200, 2);
tic
runMcCscd(cscdFltr1, wp_, 5e-6, 0, 100, [-200, 2]);
toc
drawnow;
cscdHndl = gcf;
% print('../examples/Figures/csc_fltr_1_8_1','-dpdf');
print('../examples/Figures/csc_fltr_1_8_1','-dpng');

a=1;