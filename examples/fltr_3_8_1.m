% The first two filtersare analog (continuous-time) filters. The first of
% these has an equiripple passband, whereas the second one has a monotonic
% passband.

% The third and fourth filters are digital (discrete-time) filters again
% with equiripple and monotonic passbands.

% In all cases, the filters are complex with asymmetric (in frequency)
% responses.

p = [-10 -2 0.25 0.5 6 8 10]; % initial guess at finite loss poles; note pole at zero
ni=3; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = 1; % lower passband edge
wp(2) = 4; % upper passband edge
ws = [-15 -4 -1 0.6 5 20];
as = [40 40 80 80 40 40];
Ap = 0.1; % the passband ripple in dB
px = [0];
ONE_STP = 0;
svSpecs = {p, px, wp, ws};
[p, px, wp, ws, sclFctr, shftFctr] = trnsfrm(p, px, wp, ws);
% A positive-pass continuous-time filter with a monotonic pass-band
[H, E, F, P] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
plot_crsps(H,wp,ws,'b',[-10 10 -160 0.5]);
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx(H, F, length([P]), true)
X0 = chooseTF(X1o, X1s, X2o, X2s, indic);
ordr = fndOrdr(X0);
Etf = tf(zpk(E, [], 1));
Ftf = tf(zpk(F, [], 1));
Z1 = (Etf - Ftf)/(Etf + Ftf);
[Ks Pls Rem] = getRes(Z1);
if abs(min(Ks)) < 1e-5
    disp('Filter Design is Ill-Conditioned')
end
Zin = mkZin(E, F);
lddr = ladderClass();
[X2, elem1, elem2] = rmv2PolesS(Zin, P(3), P(8), lddr);
[X3, elem3, elem4] = rmv2PolesS(X2, P(2), P(7), lddr);
[X4, elem5, elem6] = rmv2PolesS(X3, P(1), P(6), lddr);
[X5, elem7, elem8] = rmvUsingS2(X4, P(4), lddr);
[X6, elem9, elem10] = rmvUsingS2(X5, P(5), lddr);
%[X8, elem11, elem12] = rmvUsingPl(X7, P(4), 1)
[X7, elem11] = rmvSCmplx(X6, lddr);
[X8, elem12] = rmvSCmplx(X7, lddr);
[X9, elem13] = rmvSCmplx(X8, lddr);
lddr.R2 = X9.K;

lddr2 = ladderClass();
[X10, elem14] = rmvSCmplx(X2o, lddr2);

% Denormalize the ladder filter
lddr.freqScale(1/sclFctr)
lddr.freqShft(-shftFctr);
lim = [-10 10 -160 5];
wp = svSpecs{3};
ws = svSpecs{4};
[fdb, fref_db] = plotLddr(lddr,wp,ws,'b', lim);
a=1;
