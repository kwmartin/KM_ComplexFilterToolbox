p = [-0.25 0.25]; % initial guess at moveable finite loss poles
px = []; % fixed pole
ni=1; % number of loss poles at infinity
wp(1) = -0.0125; % lower passband edge
wp(2) = 0.0125; % upper passband edge
ws = [-0.125 0.125]; % lower and upper stopband frequencies
as = [20 20];

Ap = 0.1; % the passband ripple in dB
ONE_STP = 0; % treat both stop-bands as a single stop-band

%H4 should be the same as H1
H4 = dsgnDigitalFltr(p,px,ni,wp,ws,as,Ap,'monotonic');


svSpecs = {p, px, wp, ws};

[p, px, wp, ws, as] = predistortSpecs(p, px, wp, ws, as); % predistort specs

sclFctr = 1/max(abs(wp)); % scale specs for better numerical accuracy
[p, px, wp, ws] = scaleSpecs(p, px, wp, ws, sclFctr);

[H, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'monotonic');
%[H, E, F, P, e_] = design_cont_prototype(p,px,ni,wp,ws,as,Ap,'monotonic'); %This is a discrete-time design with a fixed loss-pole at dc.

plot_crsps(H,wp,ws,'b',[-20 20 -70 1]);
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx2(H, F, length([P px]), true)
X0 = chooseTF(X1o, X1s, X2o, X2s, indic);Etf = tf(zpk(E, [], 1));
lddr = ladderClass();
[X1, elem1, elem2, elem3] = rmv2XPoles(X0, P(1), P(2), lddr);
[X2, elem4] = rmvSCmplx(X1, lddr);
lddr.R2 = 1;

dispLddr(lddr);
lim = [-20 20 -70 0.5];
lddr.R2 = 1;
[gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);

[KiMtrx, KfMtrx, OutMtrx, H0] = calcSFG_Fltr3(lddr);
[Fltr] = mkSFG_Fltr2(KiMtrx, KfMtrx, OutMtrx);

rvrsScl = 1/sclFctr;
KiMtrx1 = KiMtrx*rvrsScl;
KfMtrx1 = KfMtrx*rvrsScl;
OutMtrx1 = OutMtrx;
Nout = size(OutMtrx1, 1)
KdMtrx1 = zeros(Nout, 1);

[H1, KI, KF, KO, KD, SS1] = calcSFG_DFltr(KiMtrx1, KfMtrx1, OutMtrx1, KdMtrx1);
wp = svSpecs{3};
ws = svSpecs{4};
[ax1, ax2] = plot_drsps(H1,wp,ws,'b', [-0.5 0.5 -70 1]);

% hold(ax1, 'on');
% hold(ax2, 'on');
% fshft = 0.03125;
% H2 = freq_shiftd(H1, fshft);
% plot_drsps(H2, [wp(1), wp(2) + fshft], ws, 'r', [-0.5 0.5 -70 1]);

xin = zeros(1024,1);
xin(1) = 1;
%freq_shtf = 0.1375;
freq_shtf = 0.0;
xout = simFltr(KI, KF, KO, xin, freq_shtf);
[f, ndB, dB, ym, ya] = nfft2(xout, 'g', -70, 2);

[K12, KF2, Ko2] = calcBilSS(H1);

Fltr2 = scaleFltr(Fltr, rvrsScl);
cscdFltr2 = mkCscdFltr(Fltr2, wp, rvrsScl);
cscdFltr2.plotGn(wp, ws, -70, 2);

Ki3 = KiMtrx1;
Kf3 = KfMtrx1;
N = size(OutMtrx1, 2);
Ko3 = OutMtrx1(N, :);
Kd3 = 0;

[H3, SS2] = cont2BlnrSS(Ki3, Kf3, Ko3, Kd3);

a=1;