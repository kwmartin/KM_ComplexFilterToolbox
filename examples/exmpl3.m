% The first two filtersare analog (continuous-time) filters. The first of
% these has an equiripple passband, whereas the second one has a monotonic
% passband.

% The third and fourth filters are digital (discrete-time) filters again
% with equiripple and monotonic passbands.

% In all cases, the filters are complex with asymmetric (in frequency)
% responses.

p = [-5 -3 -2 2 3 5]; % initial guess at finite loss poles; note pole at zero
ni=2; % number of loss poles at infinity
wp = []; ws = [];
wp(1) = -1; % lower passband edge
wp(2) = 1; % upper passband edge
ws = [-5 -1.5 1.5 5];
as = [60 20 20 60];
% ws = [-10 0.5 2.5 10];
% as = [60 20 20 20];
Ap = 0.1; % the passband ripple in dB
px = [];
ONE_STP = 0; %
% A positive-pass continuous-time filter with a monotonic pass-band
H = design_ctm_filt(p,px,ni,wp,ws,as,Ap,'monotonic');
hndl(2) = figure('Position',[200 200 500 600]);
plot_crsps(H,wp,ws,'b',[-10 10 -90 0.5]);

