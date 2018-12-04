% continuous-time filter with additional attenuation
% specified at negative image frequencies, 6 movable loss-poles (4 at negative
% freqquencies) two loss-poles at infinity, and a fixed loss-pole at dc,
% which allows for ac coupling

p = [-10 -5 -1 0.25 5 10]; % initial guess at finite loss poles; note pole at zero
ni=2; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = 1; % lower passband edge
wp(2) = 4; % upper passband edge
ws = [-5.5 -4 -1 0.5 4.5];
as = [20 60 60 20 20];
Ap = 0.1; % the passband ripple in dB
px = [0];

svSpecs = {p, px, wp, ws};
[p, px, wp, ws, sclFctr, shftFctr] = trnsfrm(p, px, wp, ws);

% A positive-pass continuous-time filter with a monotonic pass-band
H = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'monotonic');
plot_crsps(H,wp,ws,'b',[-10 10 -120 0.5]);
[p, px, wp, ws, H2] = invrsTrnsfrmH(H, p, px, wp, ws, sclFctr, shftFctr);
plot_crsps(H2,wp,ws,'b',[-10 10 -120 0.5]);
a=1;
