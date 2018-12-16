% very simple example with one movable loss pole and 1 loss pole at
% infinity (no fixed loss poles)

%w_shift = 1.5j;
w_shift = 0.0j;
p = [-3]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -1; % lower passband edge
wp(2) = 1; % upper passband edge
ws = [-5 -1.5 10 20];
as = [30 30 30 30];
Ap = 0.1; % the passband ripple in dB
px = [];
ONE_STP = 1;
% A positive-pass continuous-time filter with a monotonic pass-band
[H, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'monotonic');
if w_shift ~= 0
    H = freq_shift(H, w_shift);
    E = freq_shift(E, w_shift);
    F = freq_shift(F, w_shift);
    P = freq_shift(P, w_shift);
end
r_shift = imag(w_shift);
wp = wp + r_shift;
ws = ws + r_shift;
plot_crsps(H,wp,ws,'b',[-8.5 11.5 -40 0.5]);
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx2(H, F, length([P px]), true)
X0 = chooseTF(X1o, X1s, X2o, X2s, indic);
Etf = tf(zpk(E, [], 1));
Ftf = tf(zpk(F, [], 1));
Z1 = (Etf - Ftf)/(Etf + Ftf);
[Ks Pls Rem] = getRes(Z1);
if abs(min(Ks)) < 1e-5
    disp('Filter Design is Ill-Conditioned')
end

%Zin = mkZin(E, F);
%termRight = true;
%[z11] = mkXsSnglEnd(H, termRight);

lddr = ladderClass();
%[X1, elem1, elem2] = rmv2PolesS(z11, P(1), P(2), lddr);
%[X1, elem1] = rmvSCmplx(X0, lddr);
[X1, elem1, elem2] = rmvUsingS2(Z1, P(1), lddr);
%[X2, elem2, elem3] = rmv2PolesS(X0, P(1), P(2), lddr);
[X2, elem3] = rmvSCmplx(X1, lddr);
%lddr.R2 = 0.7378;
lddr.R2 = X2.K;

lddr2 = ladderClass();
[X3, elem4, elem5] = rmvUsingS2(X2o, P(1), lddr2);
[X4, elem6] = rmvSCmplx(X3, lddr2);
%[X6, elem8] = rmvSCmplx(X5, lddr2);
%lddr.R2 = X2.K;
%lddr.R2 = 1e6;
%lddr.R2 = 1;
%lddr.R1 = 0;
%lddr.makeSingleTerm();
dispLddr(lddr);
dispLddr(lddr2);
lim = [-10 10 -60 10];
%lddr.R2 = 0.7378;
% lddr.R2 = elem4.C / elem3.C;
[gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);

a=1;
