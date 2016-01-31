p = [-0.05, 0.35]; % initial guess at finite loss poles
px = [0.0 0.3];
ni=2; % number of loss poles at infinity
wp(1) = 0.10; % lower passband edge
wp(2) = 0.20; % upper passband edge
ws = [0.05 0.25];
as = [20 20];

Ap = 0.1; % the passband ripple in dB
ONE_STP = 1; % Assume we have two stop-bands with un-equal loss

% A continuous-time filter with an equi-ripple pass-band
H = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'monotonic');
hndl(3) = figure('Position',[300 200 500 600]);
%plot_drsps(H3,wp,ws,'r');
plot_crsps(H,wp,ws,'b',[-1.5 1.5 -120 0.5]);

