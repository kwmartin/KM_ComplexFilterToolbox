p = [-0.25 0.25]; % initial guess at moveable finite loss poles
px = []; % fixed pole
ni=1; % number of loss poles at infinity
wp(1) = -0.0125; % lower passband edge
wp(2) = 0.0125; % upper passband edge
ws = [-0.125 0.125]; % lower and upper stopband frequencies
as = [20 20];

Ap = 0.1; % the passband ripple in dB
ONE_STP = 0; % treat both stop-bands as a single stop-band

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
rvrsScl = 1/sclFctr;
KiMtrx1 = KiMtrx*rvrsScl;
KfMtrx1 = KfMtrx*rvrsScl;
OutMtrx1 = OutMtrx;

[Fltr] = mkSFG_Fltr2(KiMtrx1, KfMtrx1, OutMtrx1);
Nout = size(OutMtrx1, 1);
KdMtrx1 = zeros(Nout, 1);
[H1, KI, KF, KO] = calcSFG_DFltr(KiMtrx1, KfMtrx1, OutMtrx1, KdMtrx1);

% cscdFltr = cascadeClass();
wp = svSpecs{3};
ws = svSpecs{4};

%fig(2) = figure('Position',[500 200 500 600]); % This places and sizes plot figure
%[ax3, ax4] = plot_drsps(H1,wp,ws,'b', [-0.5 0.5 -70 1]);

freq_shtf =0;
cscdFltr = mkCscdFltr(Fltr, wp, 1);
tic
runMcCscd(cscdFltr, wp, -1e-4, freq_shtf, 100, [-60 2]);
toc

tic
runMC(KI, KF, KO, wp, -60, 1e-4, freq_shtf, 100);
toc



a=1;