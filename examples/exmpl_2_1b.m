p = [-5, -3, -1, 2, 5]; % initial guess at finite loss poles
%px = [0.0 3.0];
px=[];
ni=1; % number of loss poles at infinity
wp(1) = 0.5; % lower passband edge
wp(2) = 1.5; % upper passband edge
ws = [0.05 1.75];
as = [20 20];

Ap = 0.0001; % the passband ripple in dB
ONE_STP = 1; % Assume we have two stop-bands with un-equal loss

% A continuous-time filter with an equi-ripple pass-band
[H, E, F, P] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
%plot_drsps(H3,wp,ws,'r');
plot_crsps(H,wp,ws,'b',[-10 10 -120 2]);
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx2(H, F, length(P), true);
if indic == 1
  X0 = X1o;
elseif indic == 2
  X0 = X1s;
elseif indic == 3
  X0 = X2o;
elseif indic == 4
  X0 = X2s;
end
Etf = tf(zpk(E, [], 1));
Ftf = tf(zpk(F, [], 1));
Z1 = (Etf - Ftf)/(Etf + Ftf);
[Ks Pls Rem] = getRes(Z1);
if abs(min(Ks)) < 1e-5
    disp('Filter Design is Ill-Conditioned')
end
termRight = true;
[z11] = mkXsSnglEnd(H, termRight);

lddr = ladderClass();
%[X1, elem1] = rmvSCmplx(z11, lddr);
[X1, elem1, elem2] = rmvUsingS2(Z1, P(4), lddr);
[X2, elem3, elem4] = rmvUsingS2(X1, P(3), lddr);
[X3, elem5, elem6] = rmvUsingS2(X2, P(5), lddr);
[X4, elem7, elem8] = rmvUsingS2(X3, P(2), lddr);
[X5, elem9, elem10] = rmvUsingS2(X4, P(1), lddr);
[X6, elem11] = rmvSCmplx(X5, lddr);

%[X1, elem1, elem2] = rmv2PolesS(Z1, P(1), P(5), lddr);
%[X2, elem3, elem4] = rmv2PolesS(X1, P(3), P(4), lddr);
%[X3, elem5, elem6] = rmvUsingS2(X2, P(2), lddr);
%[X4, elem7] = rmvSCmplx(X3, lddr);
%[X5, elem8] = rmvSCmplx(X4, lddr);
%[X5, elem7] = rmvSCmplx(X4, lddr);
%[X6, elem8] = rmvSCmplx(X5, lddr);
%[X3, elem4, elem5] = rmv2PolesS(X2, P(2), P(6), lddr);
%[X4, elem6, elem7] = rmv2PolesS(X3, P(3), P(7), lddr);
%[X4, elem6, elem7] = rmvUsingS2(X3, P(3), lddr);
%[X5, elem8, elem9] = rmvUsingS2(X2, P(4), lddr);
%[X5, elem6, elem7] = rmv2PolesS(X3, P(3), P(4), lddr);
dispLddr(lddr);

lddr2 = ladderClass();
%p = elem7.Y/elem7.C;
%p = P(3);
%X2oP = evalfr(X2o, p);
%lstCmp = p*elem6.L + elem6.X;
%k1 = X2oP/lstCmp;
%[X6, elem10] = rmvSCmplx(X2o, lddr2);
[X7, elem11, elem12] = rmvUsingS2(X2o, P(2), lddr2);
%lddr.R2 = elem11.C/elem7.C;
%[X5, elem20, elem21] = rmvUsingS2(X2o, P(2), lddr2);
%[X6, elem10, elem11] = rmv2PolesS(X5, P(1), P(3), lddr2);
%[X7, elem22] = rmvSCmplx(X6, lddr2);
%[X6, elem10] = rmvSCmplx(X5, lddr);
%[X7, elem10] = rmvSCmplx(X6, lddr);
%[X8, elem11] = rmvSCmplx(X7, lddr);
%[X10, elem13] = rmvSCmplx(X2o, lddr);
lddr.R2 = X6.K;
disp('');
dispLddr(lddr2);

lim = [-10 10 -120 2];
[gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);

a=1;

