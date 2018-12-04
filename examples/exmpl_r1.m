%   Toolbox for the Design of Complex Filters
%   Copyright (C) 2016  Kenneth Martin

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.

%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.

%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.

warning('off', 'Control:ltiobject:TFComplex');
warning('off', 'Control:ltiobject:ZPKComplex');

p = [-5 -3 -2 2 3 5]; % initial guess at finite loss poles
ni=2; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -1; % lower passband edge
wp(2) = 1; % upper passband edge
ws = [-5 -1.5 1.5 5];
as = [60 20 20 60];
% ws = [-10 0.5 2.5 10];
% as = [60 20 20 20];
Ap = 0.001; % the passband ripple in dB
px = [];
ONE_STP = 0; %
% A positive-pass continuous-time filter with a monotonic pass-band
[H, E, F, P] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXs(H, F, length(P), true)
X0 = chooseTF(X1o, X1s, X2o, X2s, indic);
%rmvlOrdr = [5, 6, 4, -1, -1];
%rmvlTypes = [8, 8, 8, 4, 3];
%[lddr, fail] = doRmvls(rmvlTypes, rmvlOrdr, X0, imag(P), ni);
%dispLddr(lddr);
%lim = [-10 10 -150 1];
%[gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);

w_shift = 1.5j;
%w_shift = 0.0j;
if w_shift ~= 0
    H2 = freq_shift(H, w_shift).';
    E2 = freq_shift(E, w_shift).';
    F2 = freq_shift(F, w_shift).';
    P2 = freq_shift(P, w_shift).';
    wp = wp + imag(w_shift);
    ws = ws + imag(w_shift);
else
    H2 = H;
    E2 = E;
    F2 = F;
    P2 = P;
end
[X1o2, X1s2, X2o2, X2s2, maxOrdr, indic] = mkXsCmplx(H2, F2, length(P2), true);
X1 = chooseTF(X1o2, X1s2, X2o2, X2s2, indic);
%[X2, K2, k2] = rmvUsingS(X1, P(2))
%[X3, K3, k3] = rmvUsingS(X2, P(5))
%[X4, K4, k4] = rmvUsingS(X3, P(1))
%[X5, K5, k5] = rmvUsingS(X4, P(6))
%[X6, K6, k6] = rmvUsingS(X5, P(3))
%[X7, K6, k6] = rmvUsingS(X6, P(4))
Etf = tf(zpk(E2, [], 1));
Ftf = tf(zpk(F2, [], 1));
Z1 = (Etf - Ftf)/(Etf + Ftf);
[Ks Pls Rem] = getRes(Z1);
if abs(min(Ks)) < 1e-5
    disp('Filter Design is Ill-Conditioned')
end
lddr1 = ladderClass();
P = P + w_shift;
%[X2A, elem1, elem2a] = rmvUsingS2(X1, P(2));
%[X2, elem1b, elem2b] = rmvUsingS2(X2A, P(5));
[X2, elem1, elem2] = rmv2PolesS(Z1, P(2), P(5), lddr1);
[X3, elem3, elem4] = rmv2PolesS(X2, P(1), P(6), lddr1);
[X4, elem5, elem6] = rmv2PolesS(X3, P(3), P(4), lddr1);
[X5, elem7] = rmvSCmplx(X4, lddr1);
[X6, elem8] = rmvSCmplx(X5, lddr1);
lddr1.R2 = X6.K;
lim = [-5 15 -120 2];
[gn1, db1] = plot_lddr(H2,lddr1,wp,ws,'b',lim);
dispLddr(lddr1);
a=1;