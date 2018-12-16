% A continuous-time ladder design example, somewhat old
% passband is 0.25 to 2.25 rad, stop-band loss is -66dB
% and decreasing, passband ripple is small at 0.02dB

%w_shift = 1.5j;
%w_shift = 0.0j;
p = [-5 -3 -2 -1.6 1.6 2 3 5]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -1; % lower passband edge
wp(2) = 1; % upper passband edge
ws = [-15 -1.2 1.2 15];
as = [60 40 40 60];
Ap = 0.025; % the passband ripple in dB
px = [];
ONE_STP = 0;
[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, 1.25);

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

% plot the normalized transfer function
% plot_crsps(H, wp*sclFctr, ws*sclFctr, 'b', [-8.5 11.5 -40 1]);
[X1o, X1s, X2o, X2s, maxOrdr, indic] = mkXsCmplx2(H, F, length([P px]), true)
X0 = chooseTF(X1o, X1s, X2o, X2s, indic);

% Alternatively, we could have used the input impedance, Z1, found using
Etf = tf(zpk(E, [], 1));
Ftf = tf(zpk(F, [], 1));
Z1 = (Etf - Ftf)/(Etf + Ftf);
[Ks Pls Rem] = getRes(Z1);
if abs(min(Ks)) < 1e-5
    disp('Filter Design is Ill-Conditioned')
end

% Alternatively, we could have used the input impedance,  Zin, found using
Zin = mkZin(E, F);
% Alternatively, we could have designed a single-ended, right terminated
% using, z11, found from
termRight = true;
[z11] = mkXsSnglEnd(H, termRight);
% If we took this approach, we would need to reverse the ladder afterwards
% using lddr.makeSingleTerm()

lddr = ladderClass();
%[X1, elem1, elem2] = rmv2PolesS(z11, P(1), P(2), lddr);
%[X1, elem1] = rmvSCmplx(X0, lddr);
%[X1, elem1, elem2] = rmvUsingS2(X0, P(1), lddr);
%[X2, elem3, elem4] = rmvUsingS2(X1, P(2), lddr);
[X1, elem1, elem2, elem3] = rmv2XPoles(X0, P(4), P(5), lddr);
[X2, elem4, elem5, elem6] = rmv2XPoles(X1, P(3), P(6), lddr);
[X3, elem7, elem8, elem9] = rmv2XPoles(X2, P(2), P(7), lddr);
[X4, elem10, elem11, elem12] = rmv2XPoles(X3, P(1), P(8), lddr);
[X5, elem13] = rmvSCmplx(X4, lddr);
%lddr.R2 = 0.7378;
lddr.R2 = 1;

lddr2 = ladderClass();
[X6, elem14, elem15, elem16] = rmv2XPoles(X2o, P(1), P(8), lddr2);
lddr.R2 = elem14.C / elem13.C;
lim = [-10 10 -120 2];
plot_lddr(H, lddr,wp,ws,'b',lim);
%lddr.R2 = X2.K;
%lddr.R2 = 1e6;
%lddr.R2 = 1;
%lddr.R1 = 0;
%lddr.makeSingleTerm();
dispLddr(lddr);
dispLddr(lddr2);
% Denormalize the ladder filter
lddr.scale(1/sclFctr)
lddr.freqShft(-shftFctr);
dispLddr(lddr);
% denormalize the transfer function
H2 = freqScale(H, 1/sclFctr);
H3 = freq_shift(H2, -shftFctr);
% plot the transfer function and the ladder filter response
% the plot of the transfer function has 0.001 dB added so it
% can be visualized (by zooming in)
% [gn, db] = plot_lddr(H3, lddr, wp_*2*pi, ws_*2*pi, 'b', lim);

%lddr.R2 = 0.7378;
lddr.R2 = 1;
[gn, db] = plot_lddr(H3, lddr,wp_,ws_,'b',lim);

elem0 = ladderElem(0, 0, 0, 0, 'SHC');
a=1;
