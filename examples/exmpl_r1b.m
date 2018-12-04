
p = [-5 -3 -2 2 3 5]; % initial guess at finite loss poles; note pole at zero
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -1; % lower passband edge
wp(2) = 1; % upper passband edge
ws = [-5 -1.5 1.5 5];
as = [60 20 20 60];
% ws = [-10 0.5 2.5 10];
% as = [60 20 20 20];
Ap = 0.1; % the passband ripple in dB
px = [];
ONE_STP = 0; %
% A positive-pass continuous-time filter with a monotonic pass-band
[H, E, F, P] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'monotonic');
w_shift = 1.5j;
%w_shift = 0.0j;
if w_shift ~= 0
    H2 = freq_shift(H, w_shift);
    E2 = freq_shift(E, w_shift);
    F2 = freq_shift(F, w_shift);
    P2 = freq_shift(P, w_shift);
end
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXs(H2, F2, length(P), true)

r_shift = imag(w_shift);
wp = wp + r_shift;
ws = ws + r_shift;
plot_crsps(H2,wp,ws,'b',[-8.5 11.5 -80 0.5]);
e = zero2zpk(E2);
f = zero2zpk(F2);
zin_n = add_zpk(e, -f);
zin_p = invert_zpk(add_zpk(e, f));
zin = mult_zpk(zin_n, zin_p);
X0=zin;

Zin = mkZin(E2, F2);
termRight = true;
[z11] = mkXsSnglEnd(H2, termRight);

rmvlOrdr = [1, 3, 4, 6, 2, 5, -1];
rmvlTypes = [12, 12, 12, 12, 12, 12, 10];
zpk(X0)

[lddr, fail] = doCmplxRmvls(rmvlTypes, rmvlOrdr, X0, P, ni)
lim = [-8.5 11.5 -160 0.5];
lddr.R2 = 1e20;
[gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);
