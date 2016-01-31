p = [-2 -15 0 3 5]; % initial guess at finite loss poles; note pole at zero
ni=2; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = 1; % lower passband edge
wp(2) = 2; % upper passband edge
ws(1) = 0.05; % lower stopband edge
ws(2) = 2.5; % upper stopband edge
as = [20 20];
Ap = 0.1; % the passband ripple in dB
px = [];
% A positive-pass continuous-time filter with an equi-ripple pass-band
H = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'elliptic');
hndl(1) = figure('Position',[100 200 500 600]);
plot_crsps(H,wp,ws,'r');

% A positive-pass continuous-time filter with a monotonic pass-band
H = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'monotonic');
hndl(2) = figure('Position',[200 200 500 600]);
plot_crsps(H,wp,ws,'b');
