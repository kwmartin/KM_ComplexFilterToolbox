% fltr_1_5_1.m: 1 pole at infinity, 5 moveable poles, 1 fixed pole example
%
p = [-5, -3, -1, 3.0, 5.0]; % initial guess at finite loss poles
px=[0.0]; % fixed pole at zero
ni=1; % number of loss poles at infinity
% all frequency specs in radians
wp(1) = 0.5; % lower passband edge
wp(2) = 1.5; % upper passband edge
ws = [0.2 1.8]; % stop-band frequencies
as = [20 20]; % relative stop-band loss at ws frequencies
Ap = 0.02; % the passband ripple in dB
ONE_STP = 0; % Assume we have two stop-bands

% Design the normalized continuous-time filter
% Return transfer functions for normalized filter, and
% sclFctr, and shftFctr used to normalize so we can transform back
Fltr = dsgnAnalogFltr(p, px, ni, wp, ws, as, Ap, 'elliptic');
H = Fltr.H;
E = Fltr.E;
F = Fltr.F;
P = Fltr.P;
sclFctr = Fltr.sclFctr;
shftFctr = Fltr.shftFctr;

% Ladder Design
% calculate ladder two-port reactances
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx2(H, F, length(P), true);
% choose highest order function
X0 = chooseTF(X1o, X1s, X2o, X2s, indic);
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
[X1, elem1, elem2, elem3] = rmv2XPoles(X0, P(2), P(6), lddr);
[X2, elem4, elem5, elem6] = rmv2XPoles(X1, P(1), P(3), lddr);
[X3, elem7, elem8, elem9] = rmv2XPoles(X2, P(4), P(5), lddr);
[X4, elem10] = rmvSCmplx(X3, lddr);

lddr2 = ladderClass();
[X5, elem11, elem12, elem13] = rmv2XPoles(X2o, P(4), P(5), lddr2);
lddr.R2 = elem11.C / elem10.C;
%lddr.R2 = X4.K;

% Denormalize the ladder filter
lddr.freqScale(1/sclFctr)
lddr.freqShft(-shftFctr);
dispLddr(lddr);

% denormalize the transfer function
H2 = freqScale(H, 1/sclFctr);
H3 = freq_shift(H2, -shftFctr);

lim = [-10 10 -150 2];
[gn, db] = plot_lddr(H3, lddr,wp,ws,'b',lim);
dispLddr(lddr); % display the final ladder components
a=1;