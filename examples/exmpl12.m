p = [-5, -3, -1, 3.0, 5.0]; % initial guess at finite loss poles
%p = [-2, 3.0]; % initial guess at finite loss poles
%px = [0.0 3.0];
px=[0.0];
ni=1; % number of loss poles at infinity
wp(1) = 0.5; % lower passband edge
wp(2) = 1.5; % upper passband edge
ws = [0.2 1.8];
as = [20 20];

Ap = 0.02; % the passband ripple in dB
ONE_STP = 1; % Assume we have two stop-bands with un-equal loss

% A continuous-time filter with an equi-ripple pass-band
[H, E, F, P] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
%plot_drsps(H3,wp,ws,'r');
plot_crsps(H,wp,ws,'b',[-10 10 -140 0.5]);
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx2(H, F, length(P), true);
X0 = chooseTF(X1o, X1s, X2o, X2s, indic);
Etf = tf(zpk(E, [], 1));
Etf = tf(zpk(E, [], 1));
Ftf = tf(zpk(F, [], 1));
Z1 = (Etf - Ftf)/(Etf + Ftf);
[Ks Pls Rem] = getRes(Z1);
if abs(min(Ks)) < 1e-5
    disp('Filter Design is Ill-Conditioned')
end

Zin = mkZin(E, F);

[z11] = mkXsSnglEnd(H);

lddr = ladderClass();
%[X2, elem1, elem2] = rmvUsingS2(X0, P(5), lddr);
%[X3, elem3, elem4] = rmvUsingS2(X2, P(4), lddr);
%[X4, elem5, elem6] = rmvUsingS2(X3, P(6), lddr);
%[X5, elem7, elem8] = rmvUsingS2(X4, P(3), lddr);
%[X6, elem9, elem10] = rmvUsingS2(X5, P(2), lddr);
%[X7, elem11, elem12] = rmvUsingS2(X6, P(1), lddr);
[X1, elem1, elem2, elem3] = rmv2XPoles(X0, P(2), P(6), lddr);
[X2, elem4, elem5, elem6] = rmv2XPoles(X1, P(1), P(3), lddr);
[X3, elem7, elem8, elem9] = rmv2XPoles(X2, P(4), P(5), lddr);
%[X4, elem5, elem6] = rmvUsingS2(X3, P(3), lddr);
%[X5, elem7, elem8] = rmvUsingS2(X4, P(4), lddr);
[X4, elem10] = rmvSCmplx(X3, lddr);
%[X9, elem14] = rmvSCmplx(X8, lddr);
%[X10, elem15] = rmvSCmplx(X9, lddr);
%lddr.addElem(elem9);
lddr.R2 = X5.K;
%lddr.R2 = 269.1936;

lddr2 = ladderClass(lddr);
[X5, elem11, elem12, elem13] = rmv2XPoles(X2o, P(4), P(5), lddr2);
lddr.R2 = elem11.C / elem10.C;
%lddr2.makeSingleTerm();
dispLddr(lddr);

lim = [-10 10 -140 5];
[gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);
%[gn, db] = plot_lddr(H, lddr2,wp,ws,'b',lim);
a=1;

