% This example, dfltr_1_8_0.m has been deprecated by csc_fltr_1_8_0.m and
% DLddrFltr_1_8_0.m. This particular approach has way too much stop-band
% sensitivity; a superior approach has been found; still this approach is
% interesting and could lead to alternative algorithms in the future

%w_shift = pi*j;
w_shift = 0.0j;
p = [-0.25 -0.1 -0.08 0.08 0.1 0.25]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -0.025; % lower passband edge
wp(2) = 0.025; % upper passband edge
ws = [-0.49 -0.075 0.075 0.49];
as = [70 50 50 70];
Ap = 0.05; % the passband ripple in dB
px = [];
ONE_STP = 0;
% A positive-pass continuous-time filter with a elliptic pass-band

svSpecs = {p, px, wp, ws};

[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 0.05);
H4 = dsgnDigitalFltr(p_, px_, ni, wp_, ws_, as, Ap, 'elliptic');
[ax1, ax2] = plot_drsps(H4, wp_, ws_, 'b', [-0.5 0.5 -160 1]);
cscdFltr1 = mkCscdFltrD(H4, wp);
cscdFltr1.plotGn(wp_, ws_, -160, 2);
tic
runMcCscd(cscdFltr1, wp_, 1e-4, 0, 100, [-160 2]);
toc

[p, px, wp, ws, as] = predistortSpecs(p, px, wp, ws, as); % predistort specs

sclFctr = 1/max(abs(wp)); % scale specs for better numerical accuracy
[p, px, wp, ws] = scaleSpecs(p, px, wp, ws, sclFctr);

[H, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
%[H, E, F, P, e_] = design_cont_prototype(p,px,ni,wp,ws,as,Ap,'elliptic'); %This is a discrete-time design with a fixed loss-pole at dc.

if w_shift ~= 0
    H = freq_shift(H, w_shift);
    E = freq_shift(E, w_shift);
    F = freq_shift(F, w_shift);
    P = freq_shift(P, w_shift);
end
r_shift = imag(w_shift);
wp = wp + r_shift;
ws = ws + r_shift;
plot_crsps(H,wp,ws,'b',[-20 20 -140 2]);
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx2(H, F, length([P px]), true)
X0 = chooseTF(X1o, X1s, X2o, X2s, indic);
Etf = tf(zpk(E, [], 1));
Ftf = tf(zpk(F, [], 1));
Z1 = (Etf - Ftf)/(Etf + Ftf);
[Ks Pls Rem] = getRes(Z1);
if abs(min(Ks)) < 1e-5
    disp('Filter Design is Ill-Conditioned')
end

Zin = mkZin(E, F);
termRight = true;
[z11] = mkXsSnglEnd(H, termRight);

lddr = ladderClass();
%[X1, elem1, elem2] = rmv2PolesS(z11, P(1), P(2), lddr);
%[X1, elem1] = rmvSCmplx(X0, lddr);
%[X1, elem1, elem2] = rmvUsingS2(X0, P(1), lddr);
%[X2, elem3, elem4] = rmvUsingS2(X1, P(2), lddr);
[X1, elem1, elem2, elem3] = rmv2XPoles(X0, P(3), P(4), lddr);
[X2, elem4, elem5, elem6] = rmv2XPoles(X1, P(2), P(5), lddr);
[X3, elem7, elem8, elem9] = rmv2XPoles(X2, P(1), P(6), lddr);
[X4, elem10] = rmvSCmplx(X3, lddr);
%lddr.R2 = 0.7378;
lddr.R2 = 1;

lddr2 = ladderClass();
[X5, elem11, elem12] = rmv2XPoles(X2o, P(1), P(6), lddr2);
[X6, elem13, elem14] = rmv2XPoles(X5, P(2), P(5), lddr2);
[X7, elem15, elem16] = rmv2XPoles(X6, P(3), P(4), lddr2);
[X8, elem17] = rmvSCmplx(X7, lddr2);
lddr2.R1 = 1;
lddr2.R2 = 1;
%[X6, elem8] = rmvSCmplx(X5, lddr2);
%lddr.R2 = X2.K;
%lddr.R2 = 1e6;
%lddr.R2 = 1;
%lddr.R1 = 0;
%lddr.makeSingleTerm();
dispLddr(lddr);
dispLddr(lddr2);
lim = [-20 20 -160 2];
%lddr.R2 = 0.7378;
lddr.R2 = 1;
% [gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);
% [gn, db] = plot_lddr(H, lddr2,wp,ws,'r',lim);

[KiMtrx, KfMtrx, OutMtrx, H0] = calcSFG_Fltr3(lddr);
[Fltr] = mkSFG_Fltr2(KiMtrx, KfMtrx, OutMtrx);
% plot_crsps(Fltr,wp,ws,'b',[-20 20 -140 1]);

rvrsScl = 1/sclFctr;
lddr3 = scaleLddr(lddr, rvrsScl);

[KiMtrx2, KfMtrx2, OutMtrx2, H0] = calcSFG_Fltr3(lddr3);
[Fltr2] = mkSFG_Fltr2(KiMtrx2, KfMtrx2, OutMtrx2);
% plot_crsps(Fltr2,wp,ws,'b',[-2 2 -140 1]);

Nout = size(OutMtrx2, 1);
KdMtrx2 = zeros(Nout, 1);
[H1, KI, KF, KO] = calcSFG_DFltr(KiMtrx2, KfMtrx2, OutMtrx2, KdMtrx2);
wp = svSpecs{3};
ws = svSpecs{4};
% [ax1, ax2] = plot_drsps(H1,wp,ws,'b', [-0.5 0.5 -120 1]);


%hold(ax1, 'on');
%hold(ax2, 'on');
%fshft = 0.077;
%H2 = freq_shiftd(H1, fshft);
%plot_drsps(H2, wp + fshft, ws + fshft, 'r', [-0.5 0.5 -160 1]);

cscdFltr = mkCscdFltr(Fltr2, wp, rvrsScl);
% cscdFltr.plotGn(wp, ws, -120, 2);

Ki3 = KiMtrx2;
Kf3 = KfMtrx2;
N = size(OutMtrx2, 2);
Ko3 = OutMtrx2(N, :);
Kd3 = 0;

[H3, SS2] = cont2BlnrSS(Ki3, Kf3, Ko3, Kd3);

freq_shtf = 0.05;

tic
runMcCscd(cscdFltr, wp, 5e-6, freq_shtf, 100, [-160 2]);
toc
drawnow;
cscdHndl = gcf;
%print('../examples/Figures/dfltr_1_8_0_MC','-dpdf'');
print('../examples/Figures/dfltr_1_8_0_MC','-dpng');

tic
runMC(KI, KF, KO, wp, -160, 5e-6, freq_shtf, 100);
toc
drawnow;
ssHndl = gcf;
%print('../examples/Figures/dfltr_1_8_0_lddr','-dpdf');
print('../examples/Figures/dfltr_1_8_0_lddr','-dpng');

a=1;