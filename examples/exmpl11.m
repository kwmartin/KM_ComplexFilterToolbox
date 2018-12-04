% 4 loss-poles in lower stop-band, two loss-poles in upper stop-band, 2
% loss-poles at infinity; single ended (termination at load) LC realization

p = [-5, -3, -2, 2.5, 3.5]; % initial guess at finite loss poles
%px = [0.0 3.0];
px=[0.0];
ni=2; % number of loss poles at infinity
wp(1) = 0.5; % lower passband edge
wp(2) = 1.5; % upper passband edge
ws = [0.2 1.8];
as = [20 20];

Ap = 0.02; % the passband ripple in dB
ONE_STP = 0; % Assume we have two stop-bands with un-equal loss

% A continuous-time filter with an equi-ripple pass-band
[H, E, F, P] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
%plot_drsps(H3,wp,ws,'r');
plot_crsps(H,wp,ws,'b',[-10 10 -130 2]);
Porder = length(P) + length(px);
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx2(H, F, length(P), true);
X0 = chooseTF(X1o, X1s, X2o, X2s, indic);
Etf = tf(zpk(E, [], 1));
Ftf = tf(zpk(F, [], 1));
Z1 = (Etf - Ftf)/(Etf + Ftf);
[Ks Pls Rem] = getRes(Z1);
if abs(min(Ks)) < 1e-5
    disp('Filter Design is Ill-Conditioned')
end

Zin = mkZin(E, F);

[z11] = mkXsSnglEnd(H, true);

lddr = ladderClass();
[X1, elem1] = rmvSCmplx(z11, lddr);
[X2, elem2, elem3] = rmv2PolesS(X1, P(1), P(6), lddr);
[X3, elem4, elem5] = rmv2PolesS(X2, P(2), P(5), lddr);
%[X4, elem6, elem7] = rmv2PolesS(X3, P(3), P(4), lddr);
%[X4, elem6, elem7] = rmvUsingS2(X3, P(3), lddr);
%[X5, elem8, elem9] = rmvUsingS2(X4, P(4), lddr);
[X5, elem6, elem7] = rmv2PolesS(X3, P(3), P(4), lddr);
[X6, elem10] = rmvSCmplx(X5, lddr);
%[X7, elem11] = rmvSCmplx(X6, lddr);
%[X8, elem11] = rmvSCmplx(X7, lddr);
%[X10, elem13] = rmvSCmplx(X2o, lddr2);
%lddr.R2 = 1;
%lddr.R2 = X7.K;
lim = [-10 10 -130 2];
%[gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim,lddr.R2);

lddr2 = ladderClass(lddr);
lddr2.makeSingleTerm();
dispLddr(lddr2);
%lddr2.reverse();
%lddr2.R1 = 0;
%lddr2.R2 = 1;

[gn, db] = plot_lddr(H, lddr2,wp,ws,'b',lim);

a=1;

