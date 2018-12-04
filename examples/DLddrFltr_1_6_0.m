% The first two filters are analog (continuous-time) filters.

% A symetric filter that should be real

%w_shift = pi*j;
w_shift = 0.0j;
p = [-0.15 -0.1 -0.06 0.06 0.1 0.15]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -0.025; % lower passband edge
wp(2) = 0.025; % upper passband edge
ws = [-0.49 -0.049 0.049 0.49];
as = [70 50 50 70];
Ap = 0.02; % the passband ripple in dB
px = [];
ONE_STP = 0;
% A positive-pass continuous-time filter with a elliptic pass-band

svSpecs = {p, px, wp, ws};

[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.05);
% Design the normalized continuous-time filter
% Return transfer functions for normalized filter, and
% sclFctr, and shftFctr used to normalize so we can go back
Fltr = dsgnDLddrProto(p_, px_, ni, wp_, ws_, as, Ap, 'elliptic');
H = Fltr.H;
E = Fltr.E;
F = Fltr.F;
P = Fltr.P;
sclFctr = Fltr.sclFctr;
shftFctr = Fltr.shftFctr;

% plot the normalized transfer function
% plot_crsps(H, wp*sclFctr, ws*sclFctr, 'b', [-8.5 11.5 -40 1]);
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

lddr = ladderClass();

[X1, elem1, elem2, elem3] = rmv2XPoles(Zin, P(3), P(4), lddr);
[X2, elem4, elem5, elem6] = rmv2XPoles(X1, P(2), P(5), lddr);
[X3, elem7, elem8, elem9] = rmv2XPoles(X2, P(1), P(6), lddr);
[X4, elem10] = rmvSCmplx(X3, lddr);
lddr.R2 = X4.K;
% lddr.makeSingleTerm();
dispLddr(lddr);

% plot_lddr(H, lddr, 2*pi*wp*sclFctr, 2*pi*ws*sclFctr, 'b', [-25 25 -120 1]);

% Denormalize the ladder filter
[H2,lddr2] = rvrtNrmlz(H, lddr, sclFctr, shftFctr);
dispLddr(lddr2);
% plot the transfer function and the ladder filter response
% the plot of the transfer function has 0.001 dB added so it
% can be visualized (by zooming in)
% [gn, db] = plot_lddr(H2, lddr2, wp_*2*pi, ws_*2*pi, 'b', lim);
xin = zeros(8192,1);
xin(1) = 1;
xout = simLddr(lddr2, xin,  0);

% hndl = figure('Position',[800 100 600 600]);
% [ax1 ax2, f, ym] = plotRspns(xout, wp_, 'b', [-120, 2]);

tic
out = simLddrMC(lddr2, xin, wp_, 0, 2e-4, 100, [-120, 2]);
toc

drawnow;
cscdHndl = gcf;
% print('../examples/Figures/csc_fltr_1_6_0_MC','-dpdf');
print('../examples/Figures/Cscd_1_6_0_MC','-dpng');

H3 = dsgnDigitalFltr(p_, px_, ni, wp_, ws_, as, Ap, 'elliptic');
%[ax1, ax2] = plot_drsps(H3, wp_, ws_, 'b', [-0.5 0.5 -120 1]);
cscdFltr1 = mkCscdFltrD(H3, wp_);
% cscdFltr1.plotGn(wp_, ws_, -120, 2);
tic
runMcCscd(cscdFltr1, wp_, 2e-4, 0, 100, [-120, 2]);
toc

drawnow;
cscdHndl = gcf;
% print('../examples/Figures/csc_fltr_1_6_0_MC','-dpdf');
print('Figures/Cscd_1_6_0_MC','-dpng');

a=1;