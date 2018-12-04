% Relatively simple approximation with 3 movable loss-poles in lower
% stop-band, 2 movable loss-pole in upper stop-band, no loss poles at
% infinity, or fixed loss poles; larger stop-band loss around dc

p = [-10 -1 0 0.25 5 20]; % initial guess at finite loss poles; note pole at zero
ni=0; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = 1; % lower passband edge
wp(2) = 4; % upper passband edge
ws = [-5.5 -4 -1 0.5 4.5 10];
as = [20 20 50 50 20 20];
Ap = 0.1; % the passband ripple in dB
px = [];
ONE_STP = 1; % Assume we have two stop-bands with un-equal loss
% A positive-pass continuous-time filter with a monotonic pass-band
H = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
plot_crsps(H,wp,ws,'b',[-10 10 -120 0.5]);

