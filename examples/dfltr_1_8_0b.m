% An early example, now deprecated

%w_shift = pi*j;
w_shift = 0.0j;
p = [-0.25 -0.15 -0.1 -0.08 0.08 0.1 0.15 0.25]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -0.0125; % lower passband edge
wp(2) = 0.0125; % upper passband edge
ws = [-0.49 -0.075 0.075 0.49];
as = [80 60 60 80];
Ap = 0.05; % the passband ripple in dB
px = [];
ONE_STP = 0;
% A positive-pass continuous-time filter with a monotonic pass-band

svSpecs = {p, px, wp, ws};

[p, px, wp, ws, as] = predistortSpecs(p, px, wp, ws, as); % predistort specs

sclFctr = 1/max(abs(wp)); % scale specs for better numerical accuracy
[p, px, wp, ws] = scaleSpecs(p, px, wp, ws, sclFctr);

[H, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
%[H, E, F, P, e_] = design_cont_prototype(p,px,ni,wp,ws,as,Ap,'monotonic'); %This is a discrete-time design with a fixed loss-pole at dc.

if w_shift ~= 0
    H = freq_shift(H, w_shift);
    E = freq_shift(E, w_shift);
    F = freq_shift(F, w_shift);
    P = freq_shift(P, w_shift);
end
r_shift = imag(w_shift);
wp = wp + r_shift;
ws = ws + r_shift;
plot_crsps(H,wp,ws,'b',[-20 20 -300 2]);
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx2(H, F, length([P px]), true)
X0 = chooseTF(X1o, X1s, X2o, X2s, indic);Etf = tf(zpk(E, [], 1));
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
[X1, elem1, elem2, elem3] = rmv2XPoles(X0, P(2), P(7), lddr);
[X2, elem4, elem5, elem6] = rmv2XPoles(X1, P(4), P(5), lddr);
[X3, elem7, elem8, elem9] = rmv2XPoles(X2, P(3), P(6), lddr);
[X4, elem10, elem11, elem12] = rmv2XPoles(X3, P(1), P(8), lddr);
[X5, elem13] = rmvSCmplx(X4, lddr);
%lddr.R2 = 0.7378;
lddr.R2 = 1;

lddr2 = ladderClass();
[X6, elem14, elem15, elem16] = rmv2XPoles(X2o, P(1), P(8), lddr2);
[X7, elem17, elem18, elem19] = rmv2XPoles(X6, P(2), P(7), lddr2);
[X8, elem20, elem21, elem22] = rmv2XPoles(X7, P(3), P(6), lddr2);
[X9, elem23, elem24, elem25] = rmv2XPoles(X8, P(4), P(5), lddr2);
[X10, elem26] = rmvSCmplx(X9, lddr2);
lddr2.R1 = 1;
lddr2.R2 = 1;

dispLddr(lddr);
dispLddr(lddr2);
lim = [-20 20 -300 2];

lddr.R2 = 1;
[gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);
% [gn, db] = plot_lddr(H, lddr2,wp,ws,'r',lim);

[KiMtrx, KfMtrx, OutMtrx] = calcSFG_Fltr3(lddr);
[Fltr] = mkSFG_Fltr2(KiMtrx, KfMtrx, OutMtrx);
% hndl(3) = figure('Position',[800 100 500 600]);
% plot_crsps(Fltr,wp,ws,'b',[-20 20 -300 1]);

rvrsScl = 1/sclFctr;
KiMtrx1 = KiMtrx*rvrsScl;
KfMtrx1 = KfMtrx*rvrsScl;
OutMtrx1 = OutMtrx;

% lddr3 = scaleLddr(lddr, rvrsScl);
% [KiMtrx2, KfMtrx2, OutMtrx2] = calcSFG_Fltr3(lddr3);
% [Fltr2] = mkSFG_Fltr2(KiMtrx2, KfMtrx2, OutMtrx2);
% wp = svSpecs{3}*2*pi;
% ws = svSpecs{4}*2*pi;
% hndl(4) = figure('Position',[800 100 500 600]);
% plot_crsps(Fltr2,wp,ws,'b',[-2 2 -300 1]);

Nout = size(OutMtrx1, 1);
KdMtrx1 = zeros(Nout, 1);
[H1, KI, KF, KO] = calcSFG_DFltr(KiMtrx1, KfMtrx1, OutMtrx1, KdMtrx1);
%[H1, KI, KF, KO] = calcSFG_DFltr(KiMtrx2, KfMtrx2, OutMtrx2);
% hndl(5) = figure('Position',[800 100 500 600]);
% wp = svSpecs{3};
% ws = svSpecs{4};
% [ax1, ax2] = plot_drsps(H1,wp,ws,'b', [-0.5 0.5 -300 1]);

% hold(ax1, 'on');
% hold(ax2, 'on');
% fshft = 0.05;
% H2 = freq_shiftd(H1, fshft);
% plot_drsps(H2, wp + fshft, ws + fshft, 'r', [-0.5 0.5 -300 1]);
% H3 = freq_shiftd(H1, 2*fshft);
% plot_drsps(H3, wp + 2*fshft, ws + 2*fshft, 'c', [-0.5 0.5 -300 1]);

xin = zeros(8192,1);
xin(1) = 1;
freq_shtf = 0.075;
xout = simFltr(KI, KF, KO, xin, freq_shtf);
hndl(6) = figure('Position',[800 100 600 600]);
[f, ndB, dB, ym, ya] = nfft2(xout,'b', -300, 2);

a=1;
