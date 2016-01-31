pd = [0.25]; % initial guess at finite loss poles
px = [-0.4];
ni=1; % number of loss poles at infinity
wp(1) = 0.00; % lower passband edge
wp(2) = 0.0625; % upper passband edge
ws(1) = -0.025; % lower stopband edge
ws(2) = 0.125; % upper stopband edge
as = [20 20];

Ap = 0.1; % the passband ripple in dB

% A discrete-time filter with an equi-ripple pass-band
H3 = design_dtm_filt(pd,px,ni,wp,ws,as,Ap,'monotonic');
hndl(3) = figure('Position',[300 200 500 600]);
plot_drsps(H3,wp,ws,'r');

