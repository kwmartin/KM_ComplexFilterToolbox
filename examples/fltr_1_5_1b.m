% 5 movable loss poles, 3 in lower stop-band, 2 in upper stop-band,
% 1 fixed loss-pole at dc, 1 loss-pole at infinity; 0.02dB pass-band
% ripple, lower stop-band loss of -95dB


p = [-5, -3, -1, 3.0, 5.0]; % initial guess at finite loss poles
px=[0.0]; % A fixed pole at dc
ni=1; % one loss pole at infinity 
wp(1) = 0.5; % lower passband edge
wp(2) = 1.5; % upper passband edge
ws = [0.2 1.8]; % Stop-band spec
as = [20 20]; % Stop-band attenuation; not important unless unequal

Ap = 0.02; % the passband ripple in dB
ONE_STP = 1; % Consider negative and positive stop bands as a single stop-band
% A continuous-time filter with an equi-ripple pass-band
[H, E, F, P] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');

plot_crsps(H,wp,ws,'b',[-10 10 -120 0.5]);

Etf = tf(zpk(E, [], 1));
Ftf = tf(zpk(F, [], 1));
Z1 = (Etf - Ftf)/(Etf + Ftf);
[Ks Pls Rem] = getRes(Z1);
if abs(min(Ks)) < 1e-5
    disp('Filter Design is Ill-Conditioned')
end

Zin = mkZin(E, F); % In this design remove from Zin

lddr = ladderClass(); % A matlab object
% remove two poles at same time using caps and complex impedances
[X1, elem1, elem2, elem3] = rmv2XPoles(Zin, P(2), P(6), lddr);
[X2, elem4, elem5, elem6] = rmv2XPoles(X1, P(1), P(3), lddr);
[X3, elem7, elem8, elem9] = rmv2XPoles(X2, P(4), P(5), lddr);
% remove final pole at infinity
[X4, elem10] = rmvSCmplx(X3, lddr);
lddr.R2 = X4.K; % the remainder should be simply real (the load resistor)

lddr2 = ladderClass(lddr);
[X5, elem14, elem15] = rmvUsingS2(X2o, P(1), lddr2);

dispLddr(lddr);

lim = [-10 10 -140 5];
% plot_lddr() uses the built in ladder frequency analysis:
% "lddr.freqEval(s)"
[gn, db] = plot_lddr(H, lddr,wp,ws,'b',lim);

drawnow;
cscdHndl = gcf;
print('../examples/Figures/exmpl_5_1_1','-dpng');

a=1;

