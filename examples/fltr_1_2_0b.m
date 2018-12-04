% The first two filters are analog (continuous-time) filters.

% A symetric filter that should be real

w_shift = pi*2.0j;
%w_shift = 1.0j;
%w_shift = 0.0j;
p = [-3 3]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
%wp(1) = -0.618034; % lower passband edge
%wp(2) = 0.618034; % upper passband edge
wp(1) = -0.5; % lower passband edge
wp(2) = 0.5; % upper passband edge
%wp(1) = -1; % lower passband edge
%wp(2) = 1; % upper passband edge
ws = [-15 -1.5 1.5 15];
as = [40 40 40 40];
Ap = 0.25; % the passband ripple in dB
px = [];
ONE_STP = 0;
% A positive-pass continuous-time filter with a monotonic pass-band
[H, E, F, P, e_] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
if w_shift ~= 0
    H = freq_shift(H, w_shift);
    E = freq_shift(E, w_shift);
    F = freq_shift(F, w_shift);
    P = freq_shift(P, w_shift);
end
r_shift = imag(w_shift);
wp = wp + r_shift;
ws = ws + r_shift;
plot_crsps(H,wp,ws,'b',[-8.5 11.5 -80 1]);
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
[X1, elem1, elem2, elem3] = rmv2XPoles(X0, P(1), P(2), lddr);
[X2, elem4] = rmvSCmplx(X1, lddr);
lddr.R2 = 1;

dispLddr(lddr);
lim = [-10 10 -60 0.5];
lddr.R2 = 1;
[gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);

[Fltr1, Coeffs1] = mkSFG_Fltr1(lddr);
plot_crsps(Fltr1,wp,ws,'b',[-8.5 11.5 -60 1]);

[KiMtrx, KfMtrx, OutMtrx, H0] = calcSFG_Fltr3(lddr);
[Fltr2] = mkSFG_Fltr2(KiMtrx, KfMtrx, OutMtrx);

plot_crsps(Fltr2,wp,ws,'b',[-8.5 11.5 -50 1]);

a=1;