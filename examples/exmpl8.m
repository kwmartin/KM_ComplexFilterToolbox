% A narrow band ladder filter design demonstrating normalized design
% techniques, 5 movable poles, 1 loss-pole at infinity, no fixed poles,
% 0.1dB pass-band from 1 to 1.2 rad

p = [-5 -2 -1 5 7]; % initial guess at finite loss poles; note pole at zero
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = 1.0; % lower passband edge
wp(2) = 1.2; % upper passband edge
ws(1) = 0.8; % lower stopband edge
ws(2) = 1.4; % upper stopband edge
as = [20 20];
Ap = 0.1; % the passband ripple in dB
px = [];

svSpecs = {p, px, wp, ws};
[p, px, wp, ws, sclFctr, shftFctr] = trnsfrm(p, px, wp, ws);

% A positive-pass continuous-time filter with an equiripple pass-band
[H, E, F, P] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
plot_crsps(H,wp,ws,'r');

[X1o2, X1s2, X2o2, X2s2, maxOrdr, indic] = mkXsCmplx(H, F, length(P), true);
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx2(H, F, length([P px]), true)
X0 = chooseTF(X1o, X1s, X2o, X2s, indic);

%Etf = tf(zpk(E, [], 1));
%Ftf = tf(zpk(F, [], 1));
%Z1 = (Etf - Ftf)/(Etf + Ftf);
Z1 = mkZin(E, F);
[Ks Pls Rem] = getRes(Z1);
if abs(min(Ks)) < 1e-5
    disp('Filter Design is Ill-Conditioned')
end

lddr = ladderClass();
imagRoots = true;
%[X1, elem1] = rmvSCmplx(X0, lddr);
[X1, elem1, elem2] = rmvUsingS2(Z1, P(3), lddr);
[X2, elem3, elem4, elem5] = rmv2XPoles(X1, P(2), P(4), lddr);
[X3, elem6, elem7, elem8] = rmv2XPoles(X2, P(1), P(5), lddr);
%[X4, elem6, elem7] = rmv2PolesS(X3, P(2), P(5), lddr);
%[X4, elem6, elem7] = rmvUsingS2(X3, P(3), lddr);
[X4, elem9] = rmvSCmplx(X3, lddr);
%[X6, elem18] = rmvSCmplx(X5, lddr);
lddr.R2 = X4.K;

lddr2 = ladderClass();
[X5, elem10, elem11, elem12] = rmv2XPoles(X2o, P(1), P(5), lddr2);
[X5, elem13, elem14, elem15] = rmv2XPoles(X5, P(2), P(4), lddr2);
[X6, elem15, elem16] = rmvUsingS2(X5, P(3), lddr2);
[X7, elem17] = rmvSCmplx(X6, lddr2);

%[X6, elem9, elem10] = rmvUsingS2(X2o, P(1), lddr2);
%[X6, elem9, elem10] = rmv2PolesS(X2o, P(1), P(4), lddr2);
%[X7, elem11, elem12] = rmv2PolesS(X6, P(1), P(5), lddr2);
%[X8, elem13, elem14] = rmv2PolesS(X7, P(2), P(4), lddr2);
%[X10, elem16] = rmvSCmplx(X9, lddr2);
%[X11, elem17] = rmvSCmplx(X10, lddr2);
imagRoots = false;

%lddr.R2 = elem9.C/elem8.C;
lim = [-10 10 -150 2];
[gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);
dispLddr(lddr);
dispLddr(lddr2);

[p, px, wp, ws, lddr3] = invrsTrnsfrm(lddr, p, px, wp, ws, sclFctr, shftFctr);

lim = [-10 10 -150 5];
[fdb, fref_db] = plotLddr(lddr3,wp,ws,'b', lim);

a=1;