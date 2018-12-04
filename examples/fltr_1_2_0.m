% The first two filters are analog (continuous-time) filters.

% A symmetric filter that should be real

w_shift = pi*2.0j;
r_shift = imag(w_shift);

p = [-3 3]; % initial guess at finite loss poles
ni=1; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -0.5; % lower passband edge
wp(2) = 0.5; % upper passband edge
ws = [-15 -1 1 15];
as = [40 40 40 40];
Ap = 0.25; % the passband ripple in dB
px = [];

% frequency shift specs so pass band is at positive frequencies
% from 0.0125 to 0.0375
[p_, px_, wp_, ws_] = shiftSpecs(p, px, wp, ws, pi*2.0); 

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

% For this example, we will use X0 found at line 38
% get an instantiation of the ladderClass
lddr = ladderClass();
% remove the first two elements which ensure we transmission zeros,
% often called loss poles, at frequencies P(1) and P(2)
[X1, elem1, elem2, elem3] = rmv2XPoles(X0, P(1), P(2), lddr);
% remove the last loss pole at infinity
[X2, elem4] = rmvSCmplx(X1, lddr);
% set R2 of the ladder to 1
lddr.R2 = 1;

dispLddr(lddr);
lim = [-5 15 -40 1];
[gn, db] = plot_lddr(H, lddr, wp*sclFctr, ws*sclFctr, 'b', lim);

% Denormalize the ladder filte
lddr.scale(1/sclFctr)
lddr.freqShft(-shftFctr);
dispLddr(lddr);
% denormalize the transfer function
H2 = freqScale(H, 1/sclFctr);
H3 = freq_shift(H2, -shftFctr);
% plot the transfer function and the ladder filter response
% the plot of the transfer function has 0.001 dB added so it
% can be visualized (by zooming in)
[gn, db] = plot_lddr(H3, lddr, wp_, ws_, 'b', lim);
print('../examples/Figures/fltr_1_2_0','-dpng');

[KiMtrx, KfMtrx, OutMtrx, H0] = calcSFG_Fltr3(lddr);
[Fltr] = mkSFG_Fltr2(KiMtrx, KfMtrx, OutMtrx);

%plot_crsps(Fltr,wp_,ws_,'b',[-8.5 11.5 -50 1]);

TF1 = calcSFG1(lddr);
TF2 = calcSFG2(lddr);
a=1;