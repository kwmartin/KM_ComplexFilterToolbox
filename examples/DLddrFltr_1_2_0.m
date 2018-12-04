% The first two filters are analog (continuous-time) filters.

% A symmetric filter that should be real

r_shift = 0.025;

p = [-0.25  0.25]; % initial guess at moveable finite loss poles
ni=1; % number of loss poles at infinity
wp(1) = -0.0125; % lower passband edge
wp(2) = 0.0125; % upper passband edge
ws = [-0.024 0.024]; % lower and upper stopband frequencies
as = [20 20];
Ap = 0.25; % the passband ripple in dB
px = [];

% frequency shift specs so pass band is at positive frequencies
% from 0.0125 to 0.0375
[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, r_shift); 

% Design the normalized continuous-time filter
% Return transfer functions for normalized filter, and
% sclFctr, and shftFctr used to normalize so we can go back
Fltr = dsgnDLddrProto(p_, px_, ni, wp_, ws_, as, Ap, 'monotonic');
H = Fltr.H;
E = Fltr.E;
F = Fltr.F;
P = Fltr.P;
sclFctr = Fltr.sclFctr;
shftFctr = Fltr.shftFctr;

% plot the normalized transfer function
plot_crsps(H, wp*sclFctr*2*pi, ws*sclFctr*2*pi, 'b', [-8.5 11.5 -40 1]);
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx2(H, F, length([P px]), true)
X0 = chooseTF(X1o, X1s, X2o, X2s, indic);

% Alternatively, we could have used the input impedance, Z1, found using
Etf = tf(zpk(E, [], 1));
Ftf = tf(zpk(F, [], 1));
Z1 = (Etf - Ftf)/(Etf + Ftf);
[Ks Pls Rem] = getRes(Z1);
if abs(min(Ks)) < 1e-5
    disp('Filter Design is Ill-Conditioned')
end

% Alternatively, we could have used the input impedance,  Zin, found using
Zin = mkZin(E, F);
% Alternatively, we could have designed a single-ended, right terminated
% using, z11, found from
termRight = true;
[z11] = mkXsSnglEnd(H, termRight);
% If we took this approach, we would need to reverse the ladder afterwards
% using lddr.makeSingleTerm()

% For this example, we will use X0 found at line 38
% get an instantiation of the ladderClass
lddr = ladderClass();
% remove the first two elements which ensure we transmission zeros,
% often called loss poles, at frequencies P(1) and P(2)
[X1, elem1, elem2, elem3] = rmv2XPoles(X0, P(1), P(2), lddr);
% remove the last loss pole at infinity
[X2, elem4] = rmvSCmplx(X1, lddr);
% set R2 of the ladder to 1
lddr.R2 = 1;

dispLddr(lddr);
lim = [-0.5 0.5 -40 1];
% [gn, db] = plot_lddr(H, lddr, 2*pi*wp*sclFctr, 2*pi*ws*sclFctr, 'b', [-10 10 -60 1]);

% Denormalize the ladder filter
[H2,lddr2] = rvrtNrmlz(H, lddr, sclFctr, shftFctr);
dispLddr(lddr2);
% plot the transfer function and the ladder filter response
% the plot of the transfer function has 0.001 dB added so it
% can be visualized (by zooming in)
[gn, db] = plot_lddr(H2, lddr2, wp_*2*pi, ws_*2*pi, 'b', lim);
% print('../examples/Figures/fltr_1_2_0','-dpng');

tic
xin = zeros(8192,1);
xin(1) = 1;
xout = simLddr(lddr2, xin,  0);
toc

[ax1 ax2, f, ym] = plotRspns(xout, wp_, 'b', [-60, 2]);

tic
out = simLddrMC(lddr2, xin, wp_, 0, 5e-4, 100, [-60, 2]);
toc

H3 = dsgnDigitalFltr(p_, px_, ni, wp_, ws_, as, Ap, 'monotonic');
% [ax1, ax2] = plot_drsps(H3, wp_, ws_, 'b', [-0.5 0.5 -160 1]);
cscdFltr1 = mkCscdFltrD(H3, wp_);
%cscdFltr1.plotGn(wp_, ws_, -160, 2);
tic
runMcCscd(cscdFltr1, wp_, 5e-4, 0, 100, [-60, 1]);
toc

drawnow;
cscdHndl = gcf;
% print('../examples/Figures/csc_fltr_1_2_0','-dpdf');
% print('../examples/Figures/csc_fltr_1_2_0','-dpng');

a=1;