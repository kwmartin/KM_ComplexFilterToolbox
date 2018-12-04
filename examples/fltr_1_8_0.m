% The first two filters are analog (continuous-time) filters.

% A symmetric filter that should be real

tic
%w_shift = pi*j;
w_shift = 2.0j;
r_shift = imag(w_shift);
p = [-5 -3 -2 -1.6 1.6 2 3 5]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -1; % lower passband edge
wp(2) = 1; % upper passband edge
ws = [-15 -1.5 1.5 15];
as = [40 40 40 40];
Ap = 0.01; % the passband ripple in dB
px = [];
ONE_STP = 0;
% frequency shift specs so pass-band is at positive frequencies
% from 0.0125 to 0.0375
[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, r_shift); 

% Design the normalized continuous-time filter
% Return transfer functions for normalized filter, and
% sclFctr, and shftFctr used to normalize so we can go back
Fltr = dsgnAnalogFltr(p_, px_, ni, wp_, ws_, as, Ap, 'elliptic');
H = Fltr.H;
E = Fltr.E;
F = Fltr.F;
P = Fltr.P;
sclFctr = Fltr.sclFctr;
shftFctr = Fltr.shftFctr;

plot_crsps(H,wp,ws,'b',[-20 20 -160 2]);
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
%[X1, elem1, elem2, elem3] = rmv2XPoles(X0, P(4), P(5), lddr);
[X1, elem1, elem2, elem3] = rmv2XPoles(Zin, P(4), P(5), lddr);
[X2, elem4, elem5, elem6] = rmv2XPoles(X1, P(3), P(6), lddr);
[X3, elem7, elem8, elem9] = rmv2XPoles(X2, P(2), P(7), lddr);
[X4, elem10, elem11, elem12] = rmv2XPoles(X3, P(1), P(8), lddr);
[X5, elem13] = rmvSCmplx(X4, lddr);
%lddr.R2 = 0.7378;
%lddr.R2 = 1;

% Denormalize the ladder filter
lddr.scale(1/sclFctr)
lddr.freqShft(-shftFctr);
%dispLddr(lddr);
% denormalize the transfer function
H2 = freqScale(H, 1/sclFctr);
H3 = freq_shift(H2, -shftFctr);

%lddr2 = ladderClass();
%[X6, elem14, elem15] = rmv2PolesS(X2o, P(1), P(2), lddr2);
%[X7, elem16] = rmvSCmplx(X6, lddr2);
%[X6, elem8] = rmvSCmplx(X5, lddr2);
%lddr.R2 = X2.K;
%lddr.R2 = 1e6;

%lddr.makeSingleTerm();
dispLddr(lddr);
lim = [-20 20 -120 2];
%lddr.R2 = 0.7378;
%lddr.R2 = 1;
toc
[gn, db] = plot_lddr(H3, lddr,wp_,ws_,'b',lim);

elem0 = ladderElem(0, 0, 0, 0, 'SHC');

%[KiMtrx, KfMtrx, OutMtrx] = calcSFG_Fltr3(lddr);
%[Fltr2] = mkSFG_Fltr2(KiMtrx, KfMtrx, OutMtrx);
%plot_crsps(Fltr2,wp_,ws_,'b',[-20 20 -160 2]);

a=1;
