% symmetric low-pass with 6 moveable loss poles, and 2 loss-poles at
% infinity; the stop-band attenuation increases drastically at frequencies
% more removed from passband (-1 to 1); just approximation, no realization

p = [-5 -3 -2 2 3 5]; % initial guess at finite loss poles; note pole at zero
ni=2; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -1; % lower passband edge
wp(2) = 1; % upper passband edge
ws = [-5 -1.5 1.5 5];
as = [60 20 20 60];
% ws = [-10 0.5 2.5 10];
% as = [60 20 20 20];
Ap = 0.0025; % the passband ripple in dB
px = [];
ONE_STP = 0; %
% A positive-pass continuous-time filter with a monotonic pass-band
[H, E, F, P] = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
plot_crsps(H,wp,ws,'b',[-10 10 -100 0.5]);

